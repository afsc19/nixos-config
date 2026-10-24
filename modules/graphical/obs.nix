# OBS Studio, with a virtual camera (for Discord per example)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.obs;
in
{
  options.modules.graphical.obs.enable = mkEnableOption "OBS Studio with virtual camera";

  config = mkIf cfg.enable {
    # cam loopback
    # load with "sudo modprobe v4l2loopback" and unload with "sudo modprobe -r v4l2loopback"
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];

    # label it so its recognisable
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
    '';

    hm.home.packages = [
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          obs-backgroundremoval
        ];
      })
    ];
  };
}
