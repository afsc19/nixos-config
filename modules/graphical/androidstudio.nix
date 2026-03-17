# Android Studio configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.androidstudio;
in
{
  options.modules.graphical.androidstudio.enable = mkEnableOption "Android Studio";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs.unstable; [
      android-studio
    ];
  };
}
