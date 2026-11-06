# Just Brave Browser
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkForce mkMerge;
  cfg = config.modules.graphical.browser.brave;

in
{
  options.modules.graphical.browser.brave.enable = mkEnableOption "Brave Browser";


  config = mkMerge [
    {
      # https://discourse.nixos.org/t/brave-browser-has-been-dropped/81004
      modules.graphical.browser.brave.enable = mkForce false;
    }
    (mkIf cfg.enable {
      hm.programs.brave.enable = true;
      # chromecast ports
      networking.firewall.allowedUDPPortRanges = [
        {
          from = 32768;
          to = 60999;
        }
      ];
    })
  ];
}
