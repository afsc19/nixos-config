{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.laptop.battery;
  batteryPowered = config.my.hardware.batteryPowered;
  isGnome = config.modules.graphical.gnome.enable;
in
{
  options.modules.laptop.battery.enable = mkEnableOption "LAPTOP BATTERY";
  config = mkIf (cfg.enable && batteryPowered) {

    # System76 scheduler (improves CPU scheduling profiles)
    services.system76-scheduler.enable = true;
    services.system76-scheduler.settings.cfsProfiles.enable = true;

    # Enable TLP if we're NOT using GNOME
    services.tlp = {
      enable = !isGnome;
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

    # Enable power-profiles-daemon if we're using GNOME
    services.power-profiles-daemon.enable = lib.mkForce isGnome;

    # Enable powertop
    powerManagement.powertop.enable = true;

    # Enable thermald (primarily useful on Intel CPUs)
    services.thermald.enable = lib.mkDefault true;

    # upower
    services.upower.enable = true;
  };

}
