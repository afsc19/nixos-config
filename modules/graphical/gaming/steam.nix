# Equibop configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkDefault;
  cfg = config.modules.graphical.gaming.steam;
in
{
  options.modules.graphical.gaming.steam.enable = mkEnableOption "Steam";

  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;

      # Enable Gamescope session for Steam Deck-like experience
      gamescopeSession.enable = true;

      remotePlay.openFirewall = mkDefault false;
      dedicatedServer.openFirewall = mkDefault true;
      localNetworkGameTransfers.openFirewall = mkDefault false;

      protontricks.enable = true;
      
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };
  };
}
