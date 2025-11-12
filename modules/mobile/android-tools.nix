# Android tools
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.mobile.android-tools;

in
{
  options.modules.mobile.android-tools.enable = mkEnableOption "Android Tools"

  config = mkIf cfg.enable {
    programs.adb.enable = true;
    users.users.${user}.extraGroups = ["adbusers"];
    hm.home.packages = (with pkgs; [
      # adb, fastboot, etc..
      android-tools

      # Screen mirroring + UI for adb connection
      qtscrcpy

    ]);
  };
}