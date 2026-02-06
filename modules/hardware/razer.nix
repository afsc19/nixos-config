{
  pkgs,
  config,
  lib,
  user,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.hardware.razer;
in
{
  options.modules.hardware.razer.enable = mkEnableOption "razer";

  config = mkIf cfg.enable {
    hardware.openrazer.enable = true;
    hardware.openrazer.users = [ user ];

    environment.systemPackages = with pkgs; [
      polychromatic
    ];
  };
}
