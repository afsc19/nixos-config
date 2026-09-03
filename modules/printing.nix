# Printing config
# Auto-discovers network printers via Avahi/mDNS (Bonjour/AirPrint)
# Works with IPP-compatible printers yay
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.printing;
in
{
  options.modules.printing.enable = mkEnableOption "printing";

  config = mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
        epson-escpr2
        gutenprint
      ];
      browsing = true;
      defaultShared = true;
      openFirewall = true;
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    services.system-config-printer.enable = true;

    systemd.services.ensure-printers = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
