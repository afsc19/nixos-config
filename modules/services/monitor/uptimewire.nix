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
    ;
  inherit (my.uptimewire) fleet;
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
      iptables -A FORWARD -i uptimeWire0 -o uptimeWire0 -j ACCEPT
    '';

    networking.firewall.allowedUDPPorts = [ my.ports.wireguardUptimeWire ];

    networking.wireguard.interfaces.uptimeWire0 = {
      ips = [ "${thisNode.ip}/24" ];
      listenPort = my.ports.wireguardUptimeWire;
      privateKeyFile = config.age.secrets.uptimewireKey.path;

      # If we're a hub, map all excluding ourself.
      # Otherwise, only map hubs.
      peers = mapAttrsToList (name: data: {
        publicKey = data.pubkey;
        allowedIPs = if (!thisNode.isHub && data.isHub) then [ "10.100.0.0/24" ] else [ "${data.ip}/32" ];
        endpoint = if data ? endpoint then "${data.endpoint}:${toString my.ports.wireguardUptimeWire}" else null;

        # Keepalives work spoke2hub and hub2hub (to keep punching NATs between hubs).
        persistentKeepalive = mkIf (data.isHub) 25;
      }) (filterAttrs (n: d: n != config.networking.hostName && (thisNode.isHub || d.isHub)) fleet);
    };
  };
}
