# Plymouth boot animation configuration
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.modules.plymouth;

in
{
  options.modules.plymouth = {
    enable = mkEnableOption "Plymouth Boot Animation";

    # Select from https://github.com/adi1090x/plymouth-themes
    themeName = mkOption {
      type = types.str;
      default = "deus_ex";
      description = "The name of one of Aditya Shakya (@adi1090x)'s themes";
    };
  };

  config = mkIf cfg.enable {
    boot.plymouth = {
      enable = true;
      theme = config.modules.plymouth.themeName;
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = [ config.modules.plymouth.themeName ];
        })
      ];
    };

    # Enable systemd in initrd. This is required for the modern graphical 
    # LUKS unlock prompt to integrate correctly with Plymouth.
    boot.initrd.systemd.enable = true;

    # Allow Plymouth to show the animation
    boot.kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
    boot.consoleLogLevel = 0;
  };
}



