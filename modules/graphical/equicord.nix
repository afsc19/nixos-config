# Equibop configuration
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.equicord;
in
{
  options.modules.graphical.equicord.enable = mkEnableOption "Nixcord Equicord";

  config.hm = mkIf cfg.enable {
    imports = [ inputs.nixcord.homeModules.nixcord ];
    programs.nixcord = {
      enable = true;
      discord = {
        vencord.enable = false;
        equicord = {
          enable = true;
          package = pkgs.unstable.equicord; # Follow global pkgs so I can use overlays
        };
      };
      config = {
        autoUpdate = true;
        plugins = {
          fakeNitro.enable = true;
          noNitroUpsell.enable = true;
          questify.enable = true;
          spotifyActivityToggle.enable = true;
          spotifyCrack = {
            enable = false;
            noSpotifyAutoPause = false;
          };
          musicControls.enable = false;
          messageLoggerEnhanced.enable = false;
          channelTabs.enable = false;
          showHiddenChannels.enable = true;
          summaries.enable = false; # No AI crap for now
          splitLargeMessages = {
            enable = true;
            disableFileConversion = true;
          };
          previewMessage.enable = true;
        };
      };
    };
  };
}
