# XDG home configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.xdg;
in
{
  options.modules.xdg.enable = mkEnableOption "xdg";

  config.hm = mkIf cfg.enable {
    xdg.enable = true;
  };
}
