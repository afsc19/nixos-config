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
    ];

    # This is often the missing piece on NixOS for NetworkManager to actually
    # use the plugin binaries installed in the system environment.
    networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];
  };
}
