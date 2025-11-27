# Spotify configuration and themeing with Spicetify
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.laptop.bluetooth;

in
{
  options.modules.laptop.bluetooth.enable = mkEnableOption "Bluetooth"

  config = mkIf cfg.enable {

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
    
  };
}