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

  ovpnFile = ../../config/vpns/tecnico.ovpn;
  ovpn = builtins.readFile ovpnFile;

  # Extract a PEM block delimited by <tag>...</tag> from an .ovpn file.
  extract = tag: let
    afterOpen   = builtins.elemAt (builtins.split "<${tag}>" ovpn) 2;
    beforeClose = builtins.elemAt (builtins.split "</${tag}>" afterOpen) 0;
    trimmed     = builtins.match "[[:space:]]*(.*)[[:space:]]*" beforeClose;
  in builtins.elemAt trimmed 0;

  tecnicoCert = pkgs.writeText "tecnico-ca.pem" (extract "ca");
  tecnicoTa   = pkgs.writeText "tecnico-tls-auth.pem" (extract "tls-auth");
in
{
  options.modules.services.openvpn.enable = mkEnableOption "OpenVPN";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      openvpn
      # Since we use NetworkManager and also for GNOME's GUI
      networkmanager-openvpn
    ];

    # tecnico VPN
    age.secrets.tecnicoVpnPassword.file = ../../secrets/personal/tecnicoVpnPassword.age;

    networking.networkmanager.ensureProfiles = {
      environmentFiles = [ config.age.secrets.tecnicoVpnPassword.path ];
      profiles.tecnico = {
        connection = {
          id = "tecnico";
          type = "vpn";
        };
        vpn = {
          service-type = "org.freedesktop.NetworkManager.openvpn";
          connection-type = "password";
          auth = "SHA256";
          cipher = "AES-256-CBC";
          dev = "tun";
          password-flags = "0";
          remote = "vpn.tecnico.ulisboa.pt";
          remote-cert-tls = "server";
          tls-version-min = "1.2";
          ca = "${tecnicoCert}";
          ta = "${tecnicoTa}";
          ta-dir = "0";
          username = "ist1114254@tecnico.ulisboa.pt";
        };
        vpn-secrets = {
          password = "\${TECNICO_VPN_PASSWORD}";
        };
        ipv4 = {
          method = "auto";
        };
        ipv6 = {
          method = "auto";
        };
      };
    };

    # This is the missing piece that makes NetworkManager's VPN plugin
    # actually find its helper binaries.
    networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];
  };
}
