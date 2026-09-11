# Camunda Modeler for the AMS course
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.camunda;
in
{
  options.modules.graphical.camunda.enable = mkEnableOption "Camunda Modeler";

  config = mkIf cfg.enable {
    # Unstable fixes the icon
    hm.home.packages = with pkgs.unstable; [
      camunda-modeler
    ];
  };
}
