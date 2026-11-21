# dockerized Timeful (when2meet-style availability grid)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modules.services.timeful;
  secretsFile = "${cfg.folder}/secrets.env";
  backend = config.virtualisation.oci-containers.backend;
  docker = "${pkgs.docker}/bin/docker";

  # upstream has no published images, and its compose file splits the frontend into a volume so this folds frontend + server into one image
  dockerfileText = ''
    FROM node:18-alpine AS frontend
    WORKDIR /app
    COPY frontend/package*.json ./
    RUN npm ci
    COPY frontend/ .
    ARG VUE_APP_GOOGLE_CLIENT_ID=""
    ENV VUE_APP_GOOGLE_CLIENT_ID=$VUE_APP_GOOGLE_CLIENT_ID
    RUN npm run build

    FROM golang:1.25-alpine AS backend
    WORKDIR /app
    RUN apk add --no-cache git
    COPY server/ .
    # log otp codes instead of panicking when listmonk is not set up, written against cfg.rev
    COPY --from=patches otp.patch /tmp/otp.patch
    RUN patch -p2 < /tmp/otp.patch
    RUN go build -buildvcs=false -o server .

    FROM alpine:3.23
    WORKDIR /app
    RUN apk add --no-cache ca-certificates tzdata
    RUN adduser -D -g "" appuser
    COPY --from=backend /app/server .
    COPY --from=frontend /app/dist /app/frontend/dist
    RUN mkdir -p /app/logs && chown -R appuser:appuser /app
    USER appuser
    ENV FRONTEND_DIST=/app/frontend/dist
    EXPOSE 3002
    CMD ["./server", "-release=true"]
  '';
  dockerfile = pkgs.writeText "timeful.Dockerfile" dockerfileText;

  patches = pkgs.linkFarm "timeful-patches" [
    {
      name = "otp.patch";
      path = ./timeful-otp.patch;
    }
  ];

  # the build is skipped when the tag exists, so everything that goes into it has to be in the tag
  image =
    "timeful:"
    + builtins.substring 0 12 (
      builtins.hashString "sha256" (
        cfg.rev + cfg.googleClientId + dockerfileText + builtins.readFile ./timeful-otp.patch
      )
    );
in
{
  options.modules.services.timeful = {
    enable = mkEnableOption "Dockerized Timeful";
    folder = mkOption {
      type = types.str;
      default = "/var/lib/timeful";
      description = "The folder in which the database and generated secrets will be stored";
    };
    domain = mkOption {
      type = types.str;
      default = "timeful.andrecadete.com";
      description = "Public hostname of Timeful";
    };
    rev = mkOption {
      type = types.str;
      default = "743f3c6f1e29d068f29fc8417479f6278478abcd";
      description = "Upstream commit to build, bump it to update";
    };
    googleClientId = mkOption {
      type = types.str;
      default = "";
      description = "Google OAuth client id (public), baked into the frontend, the secret goes in secrets.env as CLIENT_SECRET";
    };
  };

  config = mkIf cfg.enable {
    # docker so container name resolution works on the user network, routed by traefik labels
    virtualisation.oci-containers.backend = "docker";

    modules.services.monitor.blackboxEndpoints = [
      {
        alias = "timeful";
        url = "https://${cfg.domain}";
      }
    ];

    # builds the image once per rev, the first build takes a while (npm + go)
    systemd.services.timeful-build = {
      description = "Build the Timeful docker image";
      wantedBy = [ "multi-user.target" ];
      after = [
        "docker.service"
        "network-online.target"
      ];
      requires = [ "docker.service" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "1h";
      };
      script = ''
        if ${docker} image inspect ${image} >/dev/null 2>&1; then
          exit 0
        fi
        ${docker} build -t ${image} \
          --build-context patches=${patches} \
          --build-arg VUE_APP_GOOGLE_CLIENT_ID=${lib.escapeShellArg cfg.googleClientId} \
          -f- https://github.com/schej-it/timeful.app.git#${cfg.rev} < ${dockerfile}
      '';
    };

    systemd.services."${backend}-timeful" = {
      requires = [ "timeful-build.service" ];
      after = [ "timeful-build.service" ];
    };

    # the db container starts first, so it creates the networks and the secrets for both
    systemd.services."${backend}-timeful-mongo".preStart = ''
      ${docker} network inspect timeful_internal >/dev/null 2>&1 || ${docker} network create --internal timeful_internal
      ${docker} network inspect timeful_public >/dev/null 2>&1 || ${docker} network create timeful_public

      mkdir -p ${cfg.folder}
      chmod 755 ${cfg.folder}

      if [ ! -f ${secretsFile} ]; then
        umask 077
        # the encryption key is used as a raw aes key, so it has to be exactly 32 chars
        printf '%s\n' \
          "SESSION_SECRET=$(${pkgs.openssl}/bin/openssl rand -hex 32)" \
          "ENCRYPTION_KEY=$(${pkgs.openssl}/bin/openssl rand -hex 16)" \
          > ${secretsFile}
      fi
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.folder}/mongo 0755 999 999 - -"
    ];

    virtualisation.oci-containers.containers = {
      timeful-mongo = {
        image = "mongo:7";
        pull = "always";
        volumes = [ "${cfg.folder}/mongo:/data/db" ];
        extraOptions = [
          "--network=timeful_internal"
          "--network-alias=mongo"
          "--pull=always"
        ];
      };

      timeful = {
        inherit image;
        # built locally by timeful-build
        pull = "never";
        environment = {
          MONGODB_URI = "mongodb://mongo:27017";
          GIN_MODE = "release";
          CORS_ORIGINS = "https://${cfg.domain}";
          LISTMONK_ENABLED = "false";
          CLIENT_ID = cfg.googleClientId;
        };
        environmentFiles = [ secretsFile ];
        dependsOn = [ "timeful-mongo" ];
        extraOptions = [
          "--network=timeful_internal"
          "--network=timeful_public"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.docker.network" = "timeful_public";
          "traefik.http.routers.timeful.rule" = "Host(`${cfg.domain}`)";
          "traefik.http.services.timeful.loadbalancer.server.port" = "3002";
        };
      };
    };
  };
}
