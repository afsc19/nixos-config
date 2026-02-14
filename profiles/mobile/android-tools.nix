# Android tools
{
  pkgs,
  user,
  ...
}:
{

  programs.adb.enable = true;
  users.users.${user}.extraGroups = [ "adbusers" ];
  hm.home.packages = with pkgs; [
    # adb, fastboot, etc..
    android-tools

    # Screen mirroring + UI for adb connection
    qtscrcpy

  ];

}
