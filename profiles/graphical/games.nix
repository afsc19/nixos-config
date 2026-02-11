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

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = mkDefault false;
      dedicatedServer.openFirewall = mkDefault true;
      localNetworkGameTransfers.openFirewall = mkDefault false;
    };

    home.packages = with pkgs; [
      lunar-client
    ];
  };

}
