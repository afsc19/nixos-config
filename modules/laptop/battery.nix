{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.laptop.battery;
  isGnome = config.modules.graphical.gnome.enable;
  batteryPowered = config.my.hardware.batteryPowered;
  batteryChargeLimit = config.my.hardware.batteryChargeLimit;

  # This isn't implemented (it won't be declaratively set) to use with gnome power
  batteryChargeThresholdRange = config.my.hardware.batteryChargeThresholdRange;
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
        STOP_CHARGE_THRESH_BAT0 = batteryChargeLimit;
        START_CHARGE_THRESH_BAT0 = batteryChargeLimit - batteryChargeThresholdRange;
      };
    };

    # Enable power-profiles-daemon if we're using GNOME
    services.power-profiles-daemon.enable = lib.mkForce isGnome;

    # Set battery charge limit to 80% for gnome power
    systemd.services.battery-charge-limit = mkIf isGnome {
      description = "Set battery charge limit";
      wantedBy = [
        "multi-user.target"
        "post-resume.target"
      ];
      after = [
        "multi-user.target"
        "post-resume.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        ExecStart = "${pkgs.bash}/bin/bash -c 'for bat in /sys/class/power_supply/BAT?; do if [ -e \"$bat/charge_control_end_threshold\" ]; then echo ${toString batteryChargeLimit} > \"$bat/charge_control_end_threshold\"; fi; done'";
      };
    };

    # Enable powertop
    powerManagement.powertop.enable = true;

    # Enable thermald (primarily useful on Intel CPUs)
    services.thermald.enable = lib.mkDefault true;

    # upower
    services.upower.enable = true;
  };

}
