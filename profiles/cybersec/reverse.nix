# Tools for reverse engineering
{
  pkgs,
  profiles,
  ...
}:
{
  hm.home.packages = with pkgs; [
    ghidra
    jadx
  ];

  imports = with profiles.cybersec.rev; [
    angr
    binary-ninja
    ida
  ];
}
