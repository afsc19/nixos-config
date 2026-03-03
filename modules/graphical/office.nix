# R software configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.office;
in
{
  options.modules.graphical.office.enable = mkEnableOption "Libreoffice";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      libreoffice
    ];
  };
}
