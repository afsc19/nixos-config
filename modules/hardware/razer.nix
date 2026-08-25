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

  # FIXME quick fix since kernel 7.2.0 removed strncpy from the kernel but 3.12.3 still required it
  openrazer' = {
    version = "3.12.4";
    src = pkgs.fetchFromGitHub {
      owner = "openrazer";
      repo = "openrazer";
      tag = "v3.12.4";
      hash = "sha256-WgDYs0ehnzWlX/wvfur0UhFLbZv7jZ6FMybqDaFDuLg=";
    };
  };
in
{
  options.modules.hardware.razer.enable = mkEnableOption "razer";

  config = mkIf cfg.enable {
    hardware.openrazer = {
      enable = true;
      users = [ user ];
      packages.kernel = config.boot.kernelPackages.openrazer.overrideAttrs (_: openrazer');
      packages.daemon = pkgs.python3Packages.openrazer-daemon.overrideAttrs (_: openrazer');
    };

    environment.systemPackages = with pkgs; [
      polychromatic
    ];
  };
}
