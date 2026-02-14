# Intel Hardware Acceleration configuration
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.hardware.intel;
in
{
  options.modules.hardware.intel.enable = mkEnableOption "Intel Graphics Acceleration";

  config = mkIf cfg.enable {
    # NixOS 24.11+ uses hardware.graphics
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # Required for modern Intel CPUs (iHD)
        intel-vaapi-driver # Fallback (i915)
        libvdpau-va-gl     # Bridge for VDPAU
        intel-compute-runtime # OpenCL
        vpl-gpu-rt # Video Processing Library (replaces some older media-sdk parts)
      ];
    };

    # Force the iHD driver for newer Intel hardware
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}
