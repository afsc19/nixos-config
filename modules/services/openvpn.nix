# OpenVPN configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.services.openvpn;
in
{
  options.modules.services.openvpn.enable = mkEnableOption "OpenVPN";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      openvpn
      # Since we use NetworkManager and also for GNOME's GUI
      networkmanager-openvpn
      # nm-connection-editor, also for GNOME's GUI
      network-manager-applet
    ];
  };
}
