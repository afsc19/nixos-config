# Torrenting
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.torrenting;
in
{
  options.modules.graphical.torrenting.enable = mkEnableOption "Torrenting";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      qbittorrent
    ];
  };
}
