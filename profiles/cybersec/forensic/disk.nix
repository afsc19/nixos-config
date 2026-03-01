# Disk utils
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    testdisk

    sleuthkit
    autopsy
  ];
}
