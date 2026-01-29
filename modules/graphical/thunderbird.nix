# Discord configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.thunderbird;
in
{
  options.modules.graphical.thunderbird.enable = mkEnableOption "Thunderbird";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      thunderbird
    ];
  };
}