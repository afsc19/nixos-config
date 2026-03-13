# Stremio
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.stremio;
in
{
  options.modules.graphical.stremio.enable = mkEnableOption "Stremio";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      stremio-linux-shell
    ];
  };
}
