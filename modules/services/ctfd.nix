
# dockerized CTFd
{
  config,
  lib,
  secrets,
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

  cfg = config.modules.services.ctfd;
  secretsFile = "${cfg.folder}/secrets.env";
  backend = config.virtualisation.oci-containers.backend;
in
{
  options.modules.services.ctfd = {
    enable = mkEnableOption "Dockerized CTFd";
    folder = mkOption {
      type = types.str;
      default = "/var/lib/ctfd";
      description = "The folder in which uploads, logs, db and cache will be stored";
    };
  };

  config = mkIf cfg.enable {

    # yep force docker because internal network name resolution doesnt work with podman
    virtualisation.oci-containers.backend = "docker";

    # Hook into the DB container to generate the secrets and the network before it starts
    # Because 'ctfd' depends on 'ctfd-db', this guarantees the file exists for both.
    systemd.services."${config.virtualisation.oci-containers.backend}-ctfd-db" = {
      preStart = ''
        # network creation
        ${pkgs."${backend}"}/bin/${backend} network exists ctfd_internal ||
        ${pkgs."${backend}"}/bin/${backend} network create --internal ctfd_internal

        # secrets creation
        mkdir -p ${cfg.folder}
        chmod 755 ${cfg.folder}
        
        if [ ! -f ${secretsFile} ]; then
          # generate the secrets using openssl
          ROOT_PASS=$(${pkgs.openssl}/bin/openssl rand -hex 24)
          DB_PASS=$(${pkgs.openssl}/bin/openssl rand -hex 24)
          SECRET_KEY=$(${pkgs.openssl}/bin/openssl rand -hex 64)
          
          cat <<EOF > ${secretsFile}
        MARIADB_ROOT_PASSWORD=$ROOT_PASS
        MARIADB_PASSWORD=$DB_PASS
        DATABASE_URL=mysql+pymysql://ctfd:$DB_PASS@ctfd-db/ctfd
        SECRET_KEY=$SECRET_KEY
        EOF
          
          # secure the file
          chmod 600 ${secretsFile}
        fi
      '';
    };

    # ctfd folders
    systemd.tmpfiles.rules = [
      "d ${cfg.folder}/uploads 0755 1001 1001 - -"
      "d ${cfg.folder}/logs 0755 1001 1001 - -"
      "d ${cfg.folder}/mysql 0755 999 999 - -"
      "d ${cfg.folder}/redis 0755 999 999 - -"
    ];

    virtualisation.oci-containers.containers = {
      ctfd-db = {
        image = "mariadb:10.11";
        environment = {
          # MARIADB_ROOT_PASSWORD = "ctfd";
          MARIADB_USER = "ctfd";
          # MARIADB_PASSWORD = "ctfd";
          MARIADB_DATABASE = "ctfd";
          MARIADB_AUTO_UPGRADE = "1";
        };
        environmentFiles = [ secretsFile ];
        volumes = [ "${cfg.folder}/mysql:/var/lib/mysql" ];
        cmd = [ "mysqld" "--character-set-server=utf8mb4" "--collation-server=utf8mb4_unicode_ci" "--wait_timeout=28800" "--log-warnings=0" ];
        extraOptions = [ "--network=ctfd_internal" "--network-alias=db" ];
      };

      ctfd-cache = {
        image = "redis:4";
        volumes = [ "${cfg.folder}/redis:/data" ];
        extraOptions = [ "--network=ctfd_internal" "--network-alias=cache" ];
      };

      ctfd = {
        image = "ctfd/ctfd:latest";
        environment = {
          # DATABASE_URL = "mysql+pymysql://ctfd:ctfd@ctfd-db/ctfd";
          REDIS_URL = "redis://cache:6379";
          UPLOAD_FOLDER = "/var/uploads";
          LOG_FOLDER = "/var/log/CTFd";
          WORKERS = "1";
          REVERSE_PROXY = "true";
          # SECRET_KEY = "your-long-random-secret-here";
          ACCESS_LOG = "-";
          ERROR_LOG = "-";
        };
        environmentFiles = [ secretsFile ];
        volumes = [
          "${cfg.folder}/uploads:/var/uploads"
          "${cfg.folder}/logs:/var/log/CTFd"
        ];
        ports = [ "0.0.0.0:50200:8000" ];
        dependsOn = [ "ctfd-db" "ctfd-cache" ];
        extraOptions = [ "--network=ctfd_internal" "--network-alias=ctfd" ];
      };
    };

  };
}


