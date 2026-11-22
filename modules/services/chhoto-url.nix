# chhoto url shortener, routed by traefik
{
  config,
  lib,
  secrets,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modules.services.chhoto-url;
  port = lib.my.ports.chhotoUrl;
in
{
  options.modules.services.chhoto-url = {
    enable = mkEnableOption "chhoto url shortener";
    domain = mkOption {
      type = types.str;
      default = "s.andrecadete.com";
      description = "Public hostname of chhoto url, routed by traefik";
    };
  };

  config = mkIf cfg.enable {
    # contains "password=<password>"
    age.secrets.chhotoUrlEnv = {
      file = secrets.host.chhotoUrlEnv;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    services.chhoto-url = {
      enable = true;
      environmentFiles = [ config.age.secrets.chhotoUrlEnv.path ];
      settings = {
        inherit port;
        listen_address = "127.0.0.1";
        site_url = "https://${cfg.domain}";
        allow_capital_letters = true;
      };
    };

    modules.services.traefik.exposedServices = mkIf config.modules.services.traefik.enable [
      {
        serverName = cfg.domain;
        inherit port;
      }
    ];

    modules.services.monitor.blackboxEndpoints = [
      {
        alias = "chhoto-url";
        url = "https://${cfg.domain}";
      }
    ];
  };
}
