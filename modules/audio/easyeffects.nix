# Easyeffects configuration with declarative presets
{
  config,
  lib,
  pkgs,
  configDir,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.audio.easyeffects;

  # Define your specific device name (Run `pw-cli info all` or check EasyEffects logs to find this)
  myDeviceName = "alsa_output.usb-Logitech_PRO_X_2_LIGHTSPEED_0000000000000000-00.analog-stereo";
  myDeviceDescription = "PRO X 2 LIGHTSPEED Analog Stereo";
  myDeviceRoute = "Analog Stereo";
  # Define the Preset Name
  myPresetName = "px2";

  # Use an local irs file
  impulseResponse = "${configDir}/audio/px2.irs";

in
{
  options.modules.audio.easyeffects.enable = mkEnableOption "EasyEffects";

  config = mkIf cfg.enable {

    hm = {
      # Enable EasyEffects
      services.easyeffects.enable = true;
      # FIXME TEMP https://github.com/wwmm/easyeffects/issues/4878
      # easyeffects >= 8.3.0 sets node.link-group, needed for bluetooth autoswitch to follow its filter chain
      services.easyeffects.package = pkgs.unstable.easyeffects;

      xdg.dataFile = {

        # Link the Impulse Response file
        "easyeffects/irs/${myPresetName}.irs".source = impulseResponse;

        # Create the Preset JSON
        "easyeffects/output/${myPresetName}.json".text = builtins.toJSON {
          output = {
            blocklist = [ ];
            plugins_order = [ "convolver" ];
            convolver = {
              autogain = true;
              bypass = false;
              input-gain = 0.0;
              output-gain = 0.0;
              # Important: EasyEffects looks for the filename in the 'irs' dir
              kernel-name = "${myPresetName}";
              ir-width = 100;
            };
          };
        };

        # Setup Autoloading for the specific device
        "easyeffects/autoload/output/${myDeviceName}:${myDeviceRoute}.json".text = builtins.toJSON {
          device = myDeviceName;
          device-description = myDeviceDescription;
          device-profile = myDeviceRoute;
          preset-name = myPresetName;
        };
      };
    };
  };
}
