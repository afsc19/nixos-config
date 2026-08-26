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
    hardware.openrazer = {
      enable = true;
      users = [ user ];
      packages.kernel = config.boot.kernelPackages.openrazer.overrideAttrs (_: {
        version = "unstable";
        src = pkgs.unstable.linuxPackages.openrazer.src;
      });
      packages.daemon = pkgs.python3Packages.openrazer-daemon.overrideAttrs (_: {
        version = "unstable";
        src = pkgs.unstable.openrazer-daemon.src;
      });
    };

    environment.systemPackages = with pkgs; [
      polychromatic
    ];
  };
}
