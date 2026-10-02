# Just Brave Browser
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.browser.tor;

in
{
  options.modules.graphical.browser.tor.enable = mkEnableOption "Tor Browser";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      tor-browser
    ];
  };
}
