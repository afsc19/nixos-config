# Touchpad support
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.laptop.touchpad;

in
{
  options.modules.laptop.touchpad.enable = mkEnableOption "Touchpad Support";

  config = mkIf cfg.enable {

    # Enable touchpad support (enabled default in most desktopManager).
    services.libinput.enable = true;
    services.libinput.touchpad.tapping = true; # tap
  };
}
