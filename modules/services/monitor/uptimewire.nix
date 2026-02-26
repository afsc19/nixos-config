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
    mapAttrsToList
    filterAttrs
    mkForce
    optional
    ;
  inherit (lib.my.uptimewire) fleet port;
  thisNode = fleet."${config.networking.hostName}" or null;

  cfg = config.modules.services.monitor.uptimewire;
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

    age.secrets.uptimewireKey = {
      file = secrets.host.uptimewireKey;
      owner = "systemd-network";
    };

    # TODO test ip forwarding
    boot.kernel.sysctl = mkIf thisNode.isHub {
      "net.ipv4.ip_forward" = 1;
    };
    networking.firewall.extraForwardRules = mkIf thisNode.isHub ''
      iptables -A FORWARD -i uptimeWire0 -o uptimeWire0 -p icmp -j ACCEPT
      iptables -A FORWARD -i uptimeWire0 -o uptimeWire0 -p tcp --dport ${toString my.ports.prometheus} -j ACCEPT
      iptables -A FORWARD -i uptimeWire0 -o uptimeWire0 -p tcp --dport ${toString my.ports.ssh} -j ACCEPT
      iptables -A FORWARD -i uptimeWire0 -o uptimeWire0 -j DROP
    '';

    networking.firewall.allowedUDPPorts = [ port ];

    networking.firewall.interfaces.uptimeWire0.allowedTCPPorts = [
      my.ports.prometheus
      my.ports.ssh
    ];
    networking.firewall.allowPing = true; # Just to be sure

    networking.wireguard.interfaces.uptimeWire0 = {
      ips = [ "${thisNode.ip}/24" ];
      listenPort = port;
      privateKeyFile = config.age.secrets.uptimewireKey.path;

      # If we're a hub, map all excluding ourself.
      # Otherwise, only map hubs.
      peers = mapAttrsToList (name: data: {
        publicKey = data.pubkey;
        # Use 10.100.0.0/24 so the hub can forward the packets.
        allowedIPs = if (!thisNode.isHub && data.isHub) then [ "10.100.0.0/24" ] else [ "${data.ip}/32" ];
        endpoint = if data ? endpoint then "${data.endpoint}:${toString port}" else null;

        # Keepalives work spoke2hub and hub2hub (to keep punching NATs between hubs).
        persistentKeepalive = mkIf (data.isHub) 25;
      }) (filterAttrs (n: d: n != config.networking.hostName && (thisNode.isHub || d.isHub)) fleet);
    };
  };
}
