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
