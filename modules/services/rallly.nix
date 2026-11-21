# Rallly (meeting polls)
# https://github.com/lukevella/rallly
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

  cfg = config.modules.services.rallly;
  secretsFile = "${cfg.folder}/secrets.env";
  backend = config.virtualisation.oci-containers.backend;
  docker = "${pkgs.docker}/bin/docker";
in
{
  options.modules.services.rallly = {
    enable = mkEnableOption "Dockerized Rallly";
    folder = mkOption {
      type = types.str;
      default = "/var/lib/rallly";
      description = "The folder in which the database and generated secrets will be stored";
    };
    supportEmail = mkOption {
      type = types.str;
      default = "support@andrecadete.com";
      description = "Contact address shown in the app";
    };
    domain = mkOption {
      type = types.str;
      default = "rallly.andrecadete.com";
      description = "Public hostname of Rallly";
    };
  };

  config = mkIf cfg.enable {
    # docker so container name resolution works on the user network, routed by traefik labels
    virtualisation.oci-containers.backend = "docker";

    modules.services.monitor.blackboxEndpoints = [
      {
        alias = "rallly";
        url = "https://${cfg.domain}";
      }
    ];

    # the db container starts first, so it creates the network and the secrets for both
    systemd.services."${backend}-rallly-db".preStart = ''
      ${docker} network inspect rallly_internal >/dev/null 2>&1 || ${docker} network create --internal rallly_internal
      ${docker} network inspect rallly_public >/dev/null 2>&1 || ${docker} network create rallly_public

      mkdir -p ${cfg.folder}
      chmod 755 ${cfg.folder}

      if [ ! -f ${secretsFile} ]; then
        DB_PASS=$(${pkgs.openssl}/bin/openssl rand -hex 24)
        SECRET=$(${pkgs.openssl}/bin/openssl rand -hex 32)

        umask 077
        printf '%s\n' \
          "POSTGRES_PASSWORD=$DB_PASS" \
          "DATABASE_URL=postgres://rallly:$DB_PASS@rallly-db:5432/rallly" \
          "SECRET_PASSWORD=$SECRET" \
          > ${secretsFile}
      fi
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.folder}/postgres 0700 999 999 - -"
    ];

    virtualisation.oci-containers.containers = {
      rallly-db = {
        image = "postgres:16";
        pull = "always";
        environment = {
          POSTGRES_USER = "rallly";
          POSTGRES_DB = "rallly";
        };
        environmentFiles = [ secretsFile ];
        volumes = [ "${cfg.folder}/postgres:/var/lib/postgresql/data" ];
        extraOptions = [
          "--network=rallly_internal"
          "--network-alias=rallly-db"
          "--pull=always"
        ];
      };

      rallly = {
        image = "lukevella/rallly:latest";
        pull = "always";
        environment = {
          NEXT_PUBLIC_BASE_URL = "https://${cfg.domain}";
          SUPPORT_EMAIL = cfg.supportEmail;
        };
        # smtp and other settings can be appended to this file by hand
        environmentFiles = [ secretsFile ];
        dependsOn = [ "rallly-db" ];
        extraOptions = [
          "--network=rallly_internal"
          "--network=rallly_public"
          "--pull=always"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.docker.network" = "rallly_public";
          "traefik.http.routers.rallly.rule" = "Host(`${cfg.domain}`)";
          "traefik.http.services.rallly.loadbalancer.server.port" = "3000";
        };
      };
    };
  };
}
