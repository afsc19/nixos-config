# Veracrypt
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.util.veracrypt;
in
{
  options.modules.util.veracrypt.enable = mkEnableOption "Veracrypt";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      veracrypt
    ];
  };
}
