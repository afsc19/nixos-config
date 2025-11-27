# Spotify configuration and themeing with Spicetify
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  home-manager.sharedModules = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  # Allow mDNS discovery of Google Cast devices
  networking.firewall.allowedUDPPorts = [ lib.my.ports.mdnsGoogleCast ];

  hm.programs.spicetify = {
    enable = true;
    spotifyPackage = pkgs.spotify;

    theme = pkgs.spicetify.themes.text;
    colorScheme = "Spotify";

    enabledExtensions = with pkgs.spicetify.extensions; [
      # TODO add extensions
    ];

    enabledCustomApps = with pkgs.spicetify.apps; [
      # TODO add custom apps
     ];
  };
}