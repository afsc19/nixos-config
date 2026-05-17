# Disk utils
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    unstable.testdisk

    unstable.sleuthkit
    unstable.autopsy
  ];
}
