# Windows utils
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    evtx
    my.cybersec.registry-spy
  ];
}
