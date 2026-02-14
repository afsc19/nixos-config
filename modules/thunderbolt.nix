# Thunderbolt configuration.
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.thunderbolt;
in
{
  options.modules.thunderbolt.enable = mkEnableOption "thunderbolt";

  # Use boltctl to check

  config = mkIf cfg.enable {
    services.hardware.bolt.enable = true;
  };
}
