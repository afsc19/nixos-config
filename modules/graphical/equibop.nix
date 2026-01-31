# Discord configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.equibop;
in
{
  options.modules.graphical.equibop.enable = mkEnableOption "Equibop Discord";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      equibop
    ];
  };
}
