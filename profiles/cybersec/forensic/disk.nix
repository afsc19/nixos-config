# Disk utils
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    testdisk
  ];
}