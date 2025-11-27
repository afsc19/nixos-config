# Just Brave Browser
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.browser.brave;

in
{
  options.modules.graphical.browser.brave.enable = mkEnableOption "Brave Browser"

  config = mkIf cfg.enable {
    hm.programs.brave.enable = true;
  };
}
