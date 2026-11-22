# bentopdf, a static client side pdf toolkit, served by nginx
# https://github.com/goodtab/bentopdf
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

  cfg = config.modules.services.bentopdf;
in
{
  options.modules.services.bentopdf = {
    enable = mkEnableOption "bentopdf";
    domain = mkOption {
      type = types.str;
      default = "pdf.andrecadete.com";
      description = "Public hostname of bentopdf";
    };
    acmeHost = mkOption {
      type = types.str;
      default = "andrecadete.com";
      description = "Name of the provisioned certificate to use";
    };
  };

  config = mkIf cfg.enable {
    services.bentopdf = {
      enable = true;
      package = pkgs.unstable.bentopdf;
      inherit (cfg) domain;
      nginx = {
        enable = true;
        # only used without traefik, behind it nginx.nix forces every vhost to plain http and traefik hands unclaimed hosts to nginx
        virtualHost = {
          useACMEHost = cfg.acmeHost;
          forceSSL = true;
          http2 = true;
        };
      };
    };

    modules.services.monitor.blackboxEndpoints = [
      {
        alias = "bentopdf";
        url = "https://${cfg.domain}";
      }
    ];
  };
}
