# EPUB reader
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.reader;
in
{
  options.modules.graphical.reader.enable = mkEnableOption "Reader";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs.unstable; [
      thorium-reader
    ];
  };
}
