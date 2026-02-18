# R software configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.rstudio;
in
{
  options.modules.graphical.thunderbird.enable = mkEnableOption "R Studio";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      rstudio
    ];
  };
}
