# Spotify configuration and themeing with Spicetify
{
  pkgs,
  config,
  lib,
  configDir,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.audio.easyeffects;

  # Define your specific device name (Run `pw-cli info all` or check EasyEffects logs to find this)
  myDeviceName = "alsa_output.usb-Logitech_PRO_X_2_LIGHTSPEED_0000000000000000-00.stereo-fallback";
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

      xdg.configFile = {

        # Link the Impulse Response file
        "easyeffects/irs/${myPresetName}.irs".source = impulseResponse;

        # Create the Preset JSON
        "easyeffects/output/${myPresetName}.json".text = builtins.toJSON {
          output = {
            blocklist = [ ];
            plugins_order = [ "convolverpx2" ];
            convolverpx2 = {
              autogain = true;
              bypass = false;
              input-gain = 0.0;
              output-gain = 0.0;
              # Important: EasyEffects looks for the filename in the 'irs' dir
              kernel-name = "${myPresetName}.irs";
              ir-width = 100;
            };
          };
        };

        # Setup Autoloading for the specific device
        "easyeffects/autoload/output/${myDeviceName}.json".text = builtins.toJSON {
          device = myDeviceName;
          preset = myPresetName;
        };
      };
    };
  };
}
