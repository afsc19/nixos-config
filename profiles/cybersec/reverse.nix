# Tools for reverse engineering
{
  hm,
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs.unstable; [
    # Manually download Ida PRO's binary
    ghidra
    binaryninja-free
    jadx
  ];
}