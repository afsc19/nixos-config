# A CrowdSec as an Intrusion Prevention System (IPS) configuration
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
    optionals
    ;

  cfg = config.modules.services.ipsec.crowdsec;
  nginxEnabled = config.modules.services.nginx.enable;
in
{
  options.modules.services.ipsec.crowdsec.enable = mkEnableOption "CrowdSec IPS";

  config = mkIf cfg.enable {
    services.crowdsec = {
      enable = true;

      # use LAPI
      settings = {
        general.api.server = {
          enable = true;
          listen_uri = "127.0.0.1:8080";
        };
        lapi.credentialsFile = "/var/lib/crowdsec/local_api_credentials.yaml";
        capi.credentialsFile = "/var/lib/crowdsec/online_api_credentials.yaml";
      };

      hub.collections = [
        "crowdsecurity/linux"
      ] ++ optionals nginxEnabled [
        "crowdsecurity/nginx"
      ];

      localConfig = {
        acquisitions = [
          # always ssh
          { source = "journalctl"; journalctl_filter = [ "_SYSTEMD_UNIT=ssh.service" ]; labels.type = "syslog"; }
        ] ++ optionals nginxEnabled [
          # nginx if enabled
          { source = "file"; filenames = [ "/var/log/nginx/access.log" "/var/log/nginx/error.log" ]; labels.type = "nginx"; }
        ];
      };
    };

    services.crowdsec-firewall-bouncer = {
      enable = true;
    };

    users.users.crowdsec.extraGroups = mkIf nginxEnabled [ "nginx" ];
  };
}



