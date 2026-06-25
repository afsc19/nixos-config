# Komodo deployment manager
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
    types
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

    systemd.services."${backend}-komodo-mongo" = {
      preStart = ''
        ${pkgs.docker}/bin/docker network inspect komodo >/dev/null 2>&1 ||
        ${pkgs.docker}/bin/docker network create komodo
      '';
    };

    systemd.tmpfiles.rules = [
      "d /store/komodo 0755 root root -"
      "d /store/komodo/mongo/config 0755 root root -"
      "d /store/komodo/mongo/data 0755 root root -"
      "d /store/komodo/cache 0755 root root -"
    ];

    age.secrets = {
      komodoAdminPass = {
        file = secrets.host.komodoAdminPass;
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

    virtualisation.oci-containers.containers = {
      komodo-mongo = {
        image = "mongo:7";
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

      komodo-core = {
        image = "ghcr.io/moghtech/komodo-core:latest";
        environment = {
          COMPOSE_KOMODO_IMAGE_TAG = "latest";
          H_ENABLED = "false";
          KOMODO_DATABASE_ADDRESS = "mongo:27017";
          KOMODO_DISABLE_CONFIRM_DIALOG = "true";
          KOMODO_DISABLE_NON_ADMIN_CREATE = "false";
          KOMODO_DISABLE_USER_REGISTRATION = "false";
          KOMODO_ENABLE_NEW_USERS = "false";
          KOMODO_GOOGLE_OAUTH_ENABLED = "false";
          KOMODO_HOST = "https://komodo.andrecadete.com";
          KOMODO_INIT_ADMIN_USERNAME = "admin";
          KOMODO_INIT_ADMIN_PASSWORD_FILE = config.age.secrets.komodoAdminPass.path;
          KOMODO_JWT_TTL = "1-day";
          KOMODO_LOCAL_AUTH = "true";
          KOMODO_MONITORING_INTERVAL = "15-sec";
          KOMODO_RESOURCE_POLL_INTERVAL = "5-min";
          KOMODO_TITLE = "Komodo";
          KOMODO_TRANSPARENT_MODE = "false";
        };
        volumes = [
          "/store/komodo/cache:/repo-cache:rw"
          "${config.age.secrets.komodoAdminPass.path}:${config.age.secrets.komodoAdminPass.path}:ro"
        ];
        dependsOn = [
          "komodo-mongo"
        ];
        ports = [ "127.0.0.1:9120:9120" ];
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
