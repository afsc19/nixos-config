# Komodo deployment manager (Docker)
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  cfg = config.modules.services.monitor.komodo;
  backend = config.virtualisation.oci-containers.backend;
in
{
  options.modules.services.monitor.komodo = {
    enable = mkEnableOption "Komodo deployment manager";
  };

  config = mkIf cfg.enable {

    virtualisation.oci-containers.backend = "docker";

    # --- Secrets ---
    age.secrets.komodoPasskey = {
      file = secrets.host.komodoPasskey;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    age.secrets.komodoAdminPass = {
      file = secrets.host.komodoAdminPass;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    systemd.services."${backend}-komodo-mongo".preStart = ''
      ${pkgs.docker}/bin/docker network inspect komodo >/dev/null 2>&1 ||
      ${pkgs.docker}/bin/docker network create komodo
    '';

    # secure env passkey passing
    systemd.services."${backend}-komodo-periphery".preStart = lib.mkAfter ''
      printf 'PERIPHERY_PASSKEYS=%s\n' "$(cat ${config.age.secrets.komodoPasskey.path})" \
        > /run/komodo-periphery-passkey.env
    '';

    systemd.tmpfiles.rules = [
      "d /store/komodo 0755 root root -"
      "d /store/komodo/mongo/config 0755 root root -"
      "d /store/komodo/mongo/data 0755 root root -"
      "d /store/komodo/cache 0755 root root -"
      "d /store/komodo/periphery 0755 root root -"
      "d /store/komodo/periphery-keys 0755 root root -"
    ];

    virtualisation.oci-containers.containers = {
      komodo-mongo = {
        image = "mongo:7";
        pull = "always";
        volumes = [
          "/store/komodo/mongo/config:/data/configdb:rw"
          "/store/komodo/mongo/data:/data/db:rw"
        ];
        cmd = [
          "--quiet"
          "--wiredTigerCacheSizeGB"
          "0.25"
        ];
        extraOptions = [
          "--network=komodo"
          "--network-alias=mongo"
          "--pull=always"
        ];
      };

      komodo-periphery = {
        image = "ghcr.io/moghtech/komodo-periphery:latest";
        pull = "always";
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:rw"
          "/proc:/proc:ro"
          "/store/komodo/periphery:/store/komodo/periphery:rw"
          "/store/komodo/periphery-keys:/config/keys"
        ];
        environmentFiles = [ "/run/komodo-periphery-passkey.env" ];
        environment = {
          PERIPHERY_PORT = toString lib.my.ports.komodoPeriphery;
          PERIPHERY_ROOT_DIRECTORY = "/store/komodo/periphery";
          PERIPHERY_SSL_ENABLED = "true";
        };
        extraOptions = [
          "--network=komodo"
          "--network-alias=periphery"
          "--pull=always"
        ];
      };

      komodo-core = {
        image = "ghcr.io/moghtech/komodo-core:latest";
        pull = "always";
        environment = {
          COMPOSE_KOMODO_IMAGE_TAG = "latest";
          H_ENABLED = "false";
          KOMODO_DATABASE_ADDRESS = "mongo:27017";
          KOMODO_DISABLE_CONFIRM_DIALOG = "true";
          KOMODO_DISABLE_NON_ADMIN_CREATE = "false";
          KOMODO_DISABLE_USER_REGISTRATION = "false";
          KOMODO_ENABLE_NEW_USERS = "false";
          KOMODO_FIRST_SERVER = "https://periphery:8120";
          KOMODO_GOOGLE_OAUTH_ENABLED = "false";
          KOMODO_HOST = "https://komodo.andrecadete.com";
          KOMODO_INIT_ADMIN_USERNAME = "admin";
          KOMODO_INIT_ADMIN_PASSWORD_FILE = config.age.secrets.komodoAdminPass.path;
          KOMODO_JWT_TTL = "1-day";
          KOMODO_LOCAL_AUTH = "true";
          KOMODO_PASSKEY_FILE = config.age.secrets.komodoPasskey.path;
          KOMODO_MONITORING_INTERVAL = "15-sec";
          KOMODO_RESOURCE_POLL_INTERVAL = "5-min";
          KOMODO_TITLE = "Komodo";
          KOMODO_TRANSPARENT_MODE = "false";
        };
        volumes = [
          "/store/komodo/cache:/repo-cache:rw"
          "${config.age.secrets.komodoAdminPass.path}:${config.age.secrets.komodoAdminPass.path}:ro"
          "${config.age.secrets.komodoPasskey.path}:${config.age.secrets.komodoPasskey.path}:ro"
        ];
        dependsOn = [
          "komodo-mongo"
          "komodo-periphery"
        ];
        ports = [ "127.0.0.1:${toString lib.my.ports.komodoCore}:${toString lib.my.ports.komodoCore}" ];
        extraOptions = [
          "--network=komodo"
          "--network-alias=core"
          "--pull=always"
        ];
      };
    };

    modules.services.nginx.exposedServices = mkIf config.modules.services.nginx.enable [
      {
        serverName = "komodo.andrecadete.com";
        port = lib.my.ports.komodoCore;
      }
    ];
  };
}
