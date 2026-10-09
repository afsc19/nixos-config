# Remmina remote desktop client
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.remmina;
in
{
  options.modules.graphical.remmina.enable = mkEnableOption "Remmina";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      remmina
    ];
  };
}
