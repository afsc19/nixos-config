# Asusd configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.hardware.asus;
in
{
  options.modules.hardware.asus.enable = mkEnableOption "Asusd";

  config = mkIf cfg.enable {
    services.asusd.enable = true;
  };
}
