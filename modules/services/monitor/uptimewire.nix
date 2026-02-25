# A wireguard configuration used for uptime
{
  config,
  lib,
  secrets,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    my
    my.ports
    mapAttrsToList
    filterAttrs
    ;
  cfg = config.modules.services.monitor.uptimewire;

  fleet = {
    "sylva" = {
      ip = "10.100.0.1";
      pubkey = "TODO add pubkey";
      endpoint = "world.sylva.andrecadete.com:${toString my.ports.wireguardUptimeWire}";
      isHub = true;
    };
    "favilla" = {
      ip = "10.100.0.2";
      pubkey = "TODO add pubkey";
      isHub = false;
    };
    "calidor" = {
      ip = "10.100.0.3";
      pubkey = "TODO add pubkey";
      isHub = false;
    };
  };
  thisNode = fleet."${config.networking.hostName}" or null;
  allHubs = filterAttrs (name: data: data.isHub or false) fleet;
in
{
  options.modules.services.monitor.uptimewire = {
    enable = mkEnableOption "Wireguard Uptime Wire";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = thisNode != null;
        message = "uptimewire is enabled, but host '${config.networking.hostName}' is missing from the fleet map!";
      }
    ];

    networking.firewall.allowedUDPPorts = [ my.ports.wireguardUptimeWire ];

    networking.wireguard.interfaces.uptimeWire0 = {
      ips = [ "${thisNode.ip}/24" ];
      listenPort = my.ports.wireguardUptimeWire;
      privateKeyFile = "/run/agenix/uptimewireKey";

      # If we're a hub, map all excluding ourself.
      # Otherwise, only map hubs.
      peers = mapAttrsToList (name: data: {
        publicKey = data.pubkey;
        allowedIPs = [ "${data.ip}/32" ];
        endpoint = data.endpoint or null;

        # Keepalives work spoke2hub and hub2hub (to keep punching NATs between hubs).
        persistentKeepalive = mkIf (data.isHub) 25;
      }) (filterAttrs (n: d: n != config.networking.hostName && (thisNode.isHub || d.isHub)) fleet);
    };
  };
}
