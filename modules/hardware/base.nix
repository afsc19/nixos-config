# Hardware configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.my.hardware;
in
{
  options.my.hardware = {
    batteryPowered = mkOption {
      type = types.bool;
      default = cfg.laptop;
      description = "Whether this device is battery-powered (e.g., a laptop)";
    };
    batteryChargeLimit = mkOption {
      type = types.int;
      default = 80;
      decription = "Maximum battery charge percentage (%)";
    };
    # This means the battery will always be in between (batteryChargeLimit-batteryChargeThresholdRange <===> batteryChargeLimit) %
    batteryChargeThresholdRange = mkOption {
      type = types.int;
      default = 3;
      decription = "Battery charge percentage range to trigger device recharging (%)";
    }
    laptop = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this device is a laptop";
    };
  };
}
