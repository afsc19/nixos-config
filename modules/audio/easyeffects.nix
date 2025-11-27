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

  # 1. Define your specific device name (Run `pw-cli info all` or check EasyEffects logs to find this)
  # Example: "alsa_output.pci-0000_00_1f.3.analog-stereo"
  myDeviceName = "alsa_output.usb-Logitech_PRO_X_2_LIGHTSPEED_0000000000000000-00.stereo-fallback";
  
  # 2. Define the Preset Name
  myPresetName = "px2";

  
  # Option B: Use a local file
  impulseResponse = "${configDir}/audio/px2.irs";

in
{
  options.modules.audio.easyeffects.enable = mkEnableOption "EasyEffects"

  config = mkIf cfg.enable {

    # Enable EasyEffects
    services.easyeffects.enable = true;

    # Declarative Configuration via XDG Config
    xdg.configFile = {
      
      # A. Link the Impulse Response file
      "easyeffects/irs/${myPresetName}.irs".source = impulseResponse;

      # B. Create the Preset JSON
      "easyeffects/output/${myPresetName}.json".text = builtins.toJSON {
        output = {
          blocklist = [];
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

      # C. Setup Autoloading for the specific device
      # This creates the map file that tells EasyEffects "When this device connects, load this preset"
      "easyeffects/autoload/output/${myDeviceName}.json".text = builtins.toJSON {
        device = myDeviceName;
        preset = myPresetName;
      };
    };  
  };
}