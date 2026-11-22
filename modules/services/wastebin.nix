# wastebin pastebin, routed by traefik
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

  cfg = config.modules.services.wastebin;
  port = lib.my.ports.wastebin;
  secretsDir = "/var/lib/wastebin-secrets";
  secretsFile = "${secretsDir}/secrets.env";
in
{
  options.modules.services.wastebin = {
    enable = mkEnableOption "wastebin pastebin";
    domain = mkOption {
      type = types.str;
      default = "bin.andrecadete.com";
      description = "Public hostname of wastebin, routed by traefik";
    };
    maxBodySize = mkOption {
      type = types.ints.positive;
      default = 10 * 1024 * 1024; # 500MiB
      description = "Maximum paste size in bytes";
    };
    title = mkOption {
      type = types.str;
      default = "afsc's wastebin";
      description = "Page title";
    };
  };

  config = mkIf cfg.enable {
    services.wastebin = {
      enable = true;
      settings = {
        WASTEBIN_TITLE = cfg.title;
        WASTEBIN_BASE_URL = "https://${cfg.domain}";
        WASTEBIN_ADDRESS_PORT = "127.0.0.1:${toString port}";
        WASTEBIN_MAX_BODY_SIZE = cfg.maxBodySize;
      };
      secretFile = secretsFile;
    };

    # without a fixed signing key, cookies reset on every restart and nobody can delete their pastes
    systemd.services.wastebin-secrets = {
      description = "Generate wastebin secrets";
      wantedBy = [ "multi-user.target" ];
      before = [ "wastebin.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "wastebin-secrets";
        StateDirectoryMode = "0700";
        UMask = "0077";
      };
      script = ''
        if [ ! -f ${secretsFile} ]; then
          printf '%s\n' \
            "WASTEBIN_PASSWORD_SALT=$(${pkgs.openssl}/bin/openssl rand -hex 32)" \
            "WASTEBIN_SIGNING_KEY=$(${pkgs.openssl}/bin/openssl rand -hex 64)" \
            > ${secretsFile}
        fi
      '';
    };
    systemd.services.wastebin = {
      requires = [ "wastebin-secrets.service" ];
      after = [ "wastebin-secrets.service" ];
    };

    modules.services.traefik.exposedServices = mkIf config.modules.services.traefik.enable [
      {
        serverName = cfg.domain;
        inherit port;
      }
    ];

    modules.services.monitor.blackboxEndpoints = [
      {
        alias = "wastebin";
        url = "https://${cfg.domain}";
      }
    ];
  };
}
