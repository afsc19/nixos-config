# Some games
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # Requires flatpak
  services.flatpak = {
    enable = true;
    packages = [
      "org.vinegarhq.Sober"
    ];
  };

  hm.home.packages = with pkgs; [
    lunar-client
  ];


}