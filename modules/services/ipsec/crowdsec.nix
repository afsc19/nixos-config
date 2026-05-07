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

      # Only fetch the crowdsecurity/nginx collection if Nginx is running
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



