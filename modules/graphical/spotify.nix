# Spotify configuration and themeing with Spicetify
{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.spotify;

in
{
  options.modules.graphical.spotify.enable = mkEnableOption "Spicified Spotify";

  config = mkIf cfg.enable {

    home-manager.sharedModules = [
      inputs.spicetify-nix.homeManagerModules.default
    ];

    # Allow mDNS discovery of Google Cast devices
    networking.firewall.allowedUDPPorts = [ lib.my.ports.mdnsGoogleCast ];

    # Run spotify in XWayland so it has GTK decorations instead of the ugly Mutter SSD
    hm.xdg.desktopEntries.spotify = {
      name = "Spotify";
      exec = "env -u NIXOS_OZONE_WL spotify %U";
      icon = "spotify-client";
      terminal = false;
      type = "Application";
      categories = [ "Audio" "Music" "Player" "AudioVideo" ];
    };

    hm.programs.spicetify = {
      enable = true;
      spotifyPackage = pkgs.spotify;

      theme = pkgs.spicetify.themes.sleek;
      # colorScheme = "purple";

      enabledExtensions = with pkgs.spicetify.extensions; [
        # Nothing for now
      ];

      enabledCustomApps = with pkgs.spicetify.apps; [
        marketplace
        # Nothing for now
      ];
    };
  };
}
