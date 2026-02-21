# Equibop configuration
{
  config,
  lib,
  inputs,
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
        equicord.enable = true;
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
          anammox = {
            enable = true;
          };
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
