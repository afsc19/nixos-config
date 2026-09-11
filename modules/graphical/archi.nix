# ArchiMate modelling tool
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.archi;
in
{
  options.modules.graphical.archi.enable = mkEnableOption "Archi ArchiMate modelling tool";

  config = mkIf cfg.enable {
    hm.home.packages = [ pkgs.my.archi ];
  };
}
