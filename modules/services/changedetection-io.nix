# changedetection.io, routed by traefik, vpn only by default since it has no login of its own
# https://github.com/dgtlmoon/changedetection.io/
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modules.services.changedetection-io;
  port = lib.my.ports.changedetection;
in
{
  options.modules.services.changedetection-io = {
    enable = mkEnableOption "changedetection.io";
    domain = mkOption {
      type = types.str;
      default = "changedetection.${config.networking.hostName}.andrecadete.com";
      description = "Public hostname of changedetection.io, routed by traefik";
    };
    nebulaOnly = mkOption {
      type = types.bool;
      default = true;
      description = "Restrict access to Nebula VPN IPs only, it has no authentication unless a password is set in its settings";
    };
  };

  config = mkIf cfg.enable {
    services.changedetection-io = {
      enable = true;
      behindProxy = true;
      baseURL = "https://${cfg.domain}";
      listenAddress = "127.0.0.1";
      inherit port;
    };

    modules.services.traefik.exposedServices = mkIf config.modules.services.traefik.enable [
      {
        serverName = cfg.domain;
        inherit port;
        inherit (cfg) nebulaOnly;
      }
    ];

    # the uptime monitor can't reach it when it is vpn only
    modules.services.monitor.blackboxEndpoints = mkIf (!cfg.nebulaOnly) [
      {
        alias = "changedetection";
        url = "https://${cfg.domain}";
      }
    ];
  };
}
