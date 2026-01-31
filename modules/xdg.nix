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

  # Home manager module
  config.hm = mkIf cfg.enable {
    xdg.enable = true;
  };
}
