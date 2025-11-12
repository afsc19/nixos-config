{ config, pkgs, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.laptop.battery;

in
{
  options.modules.laptop.battery.enable = mkEnableOption "LAPTOP BATTERY";
  config = mkIf cfg.enable {

    # System76 scheduler (improves CPU scheduling profiles)
    services.system76-scheduler.enable = true;
    services.system76-scheduler.settings.cfsProfiles.enable = true;

    # Enable TLP (better than gnomes internal power manager)
    services.tlp = {
      enable = true;
      settings = {
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        # Battery charge thresholds
        STOP_CHARGE_THRESH_BAT0 = 80;
        START_CHARGE_THRESH_BAT0 = 75;
      };
    };

    # TLP replaces GNOME's power-profiles-daemon
    # mkForce wins over other modules to disable it. (conflicts)
    services.power-profiles-daemon.enable = lib.mkForce false;

    # Enable powertop
    powerManagement.powertop.enable = true;

    # Enable thermald (primarily useful on Intel CPUs)
    services.thermald.enable = lib.mkDefault true;

    # upower
    services.upower.enable = true;
  };

}
