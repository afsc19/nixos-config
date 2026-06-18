# Network configuration, from diogotcorreia
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.networking = {
    wiredInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "eth0";
      description = "The main wired interface of this device";
    };
    wirelessInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "wlo1";
      description = "The main wireless interface of this device";
    };
  };

  config = {
    # Network Manager
    networking = {
      networkmanager = {
        enable = true;
        ethernet.macAddress = "stable";
        wifi.macAddress = "stable";
        dns = "none";
      };
      nameservers = [
        # cloudflare
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"

        # quad9
        "9.9.9.9"
        "149.112.112.112"
        "2620:fe::fe"
        "2620:fe::9"
      ];
    };
    usr.extraGroups = [ "networkmanager" ];

    # copy wifi certififcates to /etc/wpa_supplicant/certs/
    # https://wiki.nixos.org/wiki/Wpa_supplicant
    # https://discourse.nixos.org/t/breaking-changes-announcement-for-unstable/17574/116
    environment.etc."wpa_supplicant/certs/ist.crt" = {
      source = ../config/certs/ist.crt;
    };
  };
}
