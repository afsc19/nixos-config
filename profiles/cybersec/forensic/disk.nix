# Disk utils
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    testdisk

    unstable.sleuthkit
    unstable.autopsy
  ];
}
