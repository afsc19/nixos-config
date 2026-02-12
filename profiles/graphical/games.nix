# Some games
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  home-manager.sharedModules = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = mkDefault false;
    dedicatedServer.openFirewall = mkDefault true;
    localNetworkGameTransfers.openFirewall = mkDefault false;
  };

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
