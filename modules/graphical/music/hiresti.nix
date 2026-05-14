# Zen browser + extensions configuration
{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.music.hiresti;
  sys = pkgs.stdenv.hostPlatform.system;
in
{

  options.modules.graphical.music.hiresti.enable = mkEnableOption "Tidal HiRes TI";

  config = mkIf cfg.enable {
    hm.home.packages = [
      inputs.hires-ti.packages.${sys}.default
    ];
  };

}
