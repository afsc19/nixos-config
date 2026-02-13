# Some games
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  home-manager.sharedModules = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  modules.graphical.gaming.steam.enable = true;

  hm = {
    # Requires flatpak
    services.flatpak = {
      enable = true;
      packages = [
        "org.vinegarhq.Sober"
      ];
    };

    home.packages = with pkgs; [
      lunar-client
    ];
  };

}
