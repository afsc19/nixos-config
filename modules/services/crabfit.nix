# dockerized Crab Fit (when2meet-style availability grid), built from source at a pinned commit
# https://github.com/GRA0007/crab.fit
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

  cfg = config.modules.services.crabfit;
  secretsFile = "${cfg.folder}/secrets.env";
  backend = config.virtualisation.oci-containers.backend;
  docker = "${pkgs.docker}/bin/docker";
  repo = "https://github.com/GRA0007/crab.fit.git";

  apiDockerfileText = ''
    FROM rust:1-slim-bookworm AS builder
    RUN apt-get update && apt-get install -y --no-install-recommends pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
    WORKDIR /src
    COPY . .
    RUN cargo build --release --features sql-adaptor

    FROM debian:bookworm-slim
    RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates libssl3 && rm -rf /var/lib/apt/lists/*
    RUN useradd -m app
    COPY --from=builder /src/target/release/crabfit-api /usr/local/bin/crabfit-api
    USER app
    EXPOSE 3000
    CMD ["crabfit-api"]
  '';

  # the api url is baked into the frontend at build time
  frontendDockerfileText = ''
    FROM node:20-alpine
    WORKDIR /app
    COPY package.json yarn.lock ./
    RUN yarn install --frozen-lockfile
    COPY . .
    ARG NEXT_PUBLIC_API_URL
    ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
    ENV NEXT_TELEMETRY_DISABLED=1
    RUN yarn build
    ENV NODE_ENV=production
    EXPOSE 3000
    CMD ["yarn", "start"]
  '';

  apiDockerfile = pkgs.writeText "crabfit-api.Dockerfile" apiDockerfileText;
  frontendDockerfile = pkgs.writeText "crabfit-frontend.Dockerfile" frontendDockerfileText;

  # the build is skipped when the tag exists, so everything that goes into it has to be in the tag
  tag = text: builtins.substring 0 12 (builtins.hashString "sha256" text);
  apiImage = "crabfit-api:${tag (cfg.rev + apiDockerfileText)}";
  frontendImage = "crabfit-frontend:${tag (cfg.rev + cfg.apiDomain + frontendDockerfileText)}";
in
{
  options.modules.services.crabfit = {
    enable = mkEnableOption "Dockerized Crab Fit";
    folder = mkOption {
      type = types.str;
      default = "/var/lib/crabfit";
      description = "The folder in which the database and generated secrets will be stored";
    };
    domain = mkOption {
      type = types.str;
      default = "crabfit.andrecadete.com";
      description = "Public hostname of the frontend";
    };
    apiDomain = mkOption {
      type = types.str;
      default = "crabfit-api.andrecadete.com";
      description = "Public hostname of the api, the frontend talks to it from the browser, so it can't share the frontend host";
    };
    rev = mkOption {
      type = types.str;
      default = "628f9eefc300bf1ed3d6cc3323332c2ed9b8a350";
      description = "Upstream commit to build, bump it to update";
    };
  };

  config = mkIf cfg.enable {
    # docker so container name resolution works on the user network, routed by traefik labels
    virtualisation.oci-containers.backend = "docker";

    modules.services.monitor.blackboxEndpoints = [
      {
        alias = "crabfit";
        url = "https://${cfg.domain}";
      }
    ];

    # builds the images once per rev, the first build takes a while (rust + yarn)
    systemd.services.crabfit-build = {
      description = "Build the Crab Fit docker images";
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
        TimeoutStartSec = "2h";
      };
      script = ''
        if ! ${docker} image inspect ${apiImage} >/dev/null 2>&1; then
          ${docker} build -t ${apiImage} -f- ${repo}#${cfg.rev}:api < ${apiDockerfile}
        fi
        if ! ${docker} image inspect ${frontendImage} >/dev/null 2>&1; then
          ${docker} build -t ${frontendImage} \
            --build-arg NEXT_PUBLIC_API_URL=${lib.escapeShellArg "https://${cfg.apiDomain}"} \
            -f- ${repo}#${cfg.rev}:frontend < ${frontendDockerfile}
        fi
      '';
    };

    systemd.services."${backend}-crabfit-api" = {
      requires = [ "crabfit-build.service" ];
      after = [ "crabfit-build.service" ];
    };
    systemd.services."${backend}-crabfit" = {
      requires = [ "crabfit-build.service" ];
      after = [ "crabfit-build.service" ];
    };

    # the db container starts first, so it creates the networks and the secrets for both
    systemd.services."${backend}-crabfit-db".preStart = ''
      ${docker} network inspect crabfit_internal >/dev/null 2>&1 || ${docker} network create --internal crabfit_internal
      ${docker} network inspect crabfit_public >/dev/null 2>&1 || ${docker} network create crabfit_public

      mkdir -p ${cfg.folder}
      chmod 755 ${cfg.folder}

      if [ ! -f ${secretsFile} ]; then
        DB_PASS=$(${pkgs.openssl}/bin/openssl rand -hex 24)

        umask 077
        printf '%s\n' \
          "POSTGRES_PASSWORD=$DB_PASS" \
          "DATABASE_URL=postgres://crabfit:$DB_PASS@crabfit-db:5432/crabfit" \
          "CRON_KEY=$(${pkgs.openssl}/bin/openssl rand -hex 24)" \
          > ${secretsFile}
      fi
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.folder}/postgres 0700 999 999 - -"
    ];

    virtualisation.oci-containers.containers = {
      crabfit-db = {
        image = "postgres:16";
        pull = "always";
        environment = {
          POSTGRES_USER = "crabfit";
          POSTGRES_DB = "crabfit";
        };
        environmentFiles = [ secretsFile ];
        volumes = [ "${cfg.folder}/postgres:/var/lib/postgresql/data" ];
        extraOptions = [
          "--network=crabfit_internal"
          "--network-alias=crabfit-db"
          "--pull=always"
        ];
      };

      crabfit-api = {
        image = apiImage;
        # built locally by crabfit-build
        pull = "never";
        environment = {
          FRONTEND_URL = "https://${cfg.domain}";
        };
        # DATABASE_URL and CRON_KEY come from the generated file
        environmentFiles = [ secretsFile ];
        dependsOn = [ "crabfit-db" ];
        extraOptions = [
          "--network=crabfit_internal"
          "--network=crabfit_public"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.docker.network" = "crabfit_public";
          "traefik.http.routers.crabfit-api.rule" = "Host(`${cfg.apiDomain}`)";
          "traefik.http.services.crabfit-api.loadbalancer.server.port" = "3000";
        };
      };

      crabfit = {
        image = frontendImage;
        pull = "never";
        environment = {
          NEXT_PUBLIC_API_URL = "https://${cfg.apiDomain}";
        };
        extraOptions = [ "--network=crabfit_public" ];
        labels = {
          "traefik.enable" = "true";
          "traefik.docker.network" = "crabfit_public";
          "traefik.http.routers.crabfit.rule" = "Host(`${cfg.domain}`)";
          "traefik.http.services.crabfit.loadbalancer.server.port" = "3000";
        };
      };
    };
  };
}
