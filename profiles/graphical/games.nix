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
