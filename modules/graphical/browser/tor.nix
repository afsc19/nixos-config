# Just Brave Browser
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.browser.tor;

in
{
  options.modules.graphical.browser.tor.enable = mkEnableOption "Tor Browser";

  config = mkIf cfg.enable {
    hm.programs.tor-browser.enable = true;
  };
}
