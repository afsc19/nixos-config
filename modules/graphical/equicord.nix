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
          # FIXME temp Questify depends on AudioPlayerAPI, which breaks notification sounds (as of 14/10/2026)
          questify.enable = false;
          spotifyCrack = {
            enable = false;
            noSpotifyAutoPause = false;
          };
          musicControls.enable = false;
          channelTabs.enable = false;
          showHiddenChannels.enable = true;
          previewMessage.enable = true;
          fixSpotifyEmbeds.enable = true;
          disableCallIdle.enable = true;
          iRememberYou.enable = true;
          messageLoggerEnhanced.enable = true;
          permissionsViewer.enable = true;
          youtubeAdblock.enable = true;
        };
      };
    };
  };
}
