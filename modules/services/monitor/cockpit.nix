# Cockpit server management dashboard
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  cfg = config.modules.services.monitor.cockpit;
in
{
  options.modules.services.monitor.cockpit = {
    enable = mkEnableOption "Cockpit server management dashboard";
  };

  config = mkIf cfg.enable {
    services.cockpit = {
      enable = true;
      port = lib.my.ports.cockpit;
      settings = {
        WebService = {
          AllowUnencrypted = true;
          Origins = "https://cockpit.sylva.andrecadete.com";
        };
      };
    };

    modules.services.nginx.exposedServices = mkIf config.modules.services.nginx.enable [
      {
        serverName = "cockpit.sylva.andrecadete.com";
        port = lib.my.ports.cockpit;
      }
    ];
  };
}
