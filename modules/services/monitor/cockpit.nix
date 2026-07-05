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
    mkForce
    ;

  cfg = config.modules.services.monitor.cockpit;
in
{
  options.modules.services.monitor.cockpit = {
    enable = mkEnableOption "Cockpit server management dashboard";
  };

  config = mkIf cfg.enable {
    security.polkit.enable = true;

    services.cockpit = {
      enable = true;
      port = lib.my.ports.cockpit;
      settings = {
        WebService = {
          AllowUnencrypted = true;
          Origins = mkForce "https://localhost:${toString lib.my.ports.cockpit}";
        };
      };
    };

    modules.services.nginx.exposedServices = mkIf config.modules.services.nginx.enable [
      {
        serverName = "cockpit.${config.networking.hostName}.andrecadete.com";
        port = lib.my.ports.cockpit;
        nebulaOnly = true;
        acmeHost = "${config.networking.hostName}.andrecadete.com";
      }
    ];
  };
}
