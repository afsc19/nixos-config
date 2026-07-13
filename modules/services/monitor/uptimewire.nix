# A wireguard configuration used for uptime
{
  config,
  lib,
  secrets,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    my
    mapAttrsToList
    filterAttrs
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

    boot.kernel.sysctl = mkIf thisNode.isHub {
      "net.ipv4.ip_forward" = 1;
    };
    networking.firewall.extraForwardRules = mkIf thisNode.isHub ''
      iptables -I FORWARD -i uptimeWire0 -o uptimeWire0 -j DROP
      iptables -I FORWARD -i uptimeWire0 -o uptimeWire0 -p tcp --dport ${toString my.ports.ssh} -j ACCEPT
      iptables -I FORWARD -i uptimeWire0 -o uptimeWire0 -p tcp --dport ${toString my.ports.prometheus} -j ACCEPT
      iptables -I FORWARD -i uptimeWire0 -o uptimeWire0 -p icmp -j ACCEPT
    '';

    networking.firewall.allowedUDPPorts = [ port ];

    networking.firewall.interfaces.uptimeWire0.allowedTCPPorts = [
      my.ports.prometheusExporter
      my.ports.grafana
      my.ports.ssh
    ]
    ++ (optional thisNode.isHub my.ports.prometheusServer);
    networking.firewall.allowPing = true; # Just to be sure

    networking.wireguard.interfaces.uptimeWire0 = {
      ips = [ "${thisNode.ip}/24" ];
      listenPort = port;
      privateKeyFile = config.age.secrets.uptimewireKey.path;

      # If we're a hub, map all excluding ourself.
      # Otherwise, only map hubs.
      peers = mapAttrsToList (
        _name: data:
        let
          toHub = !thisNode.isHub && data.isHub;
          spokeAllowedIPs =
            let
              hubNames = builtins.attrNames (filterAttrs (_n: d: d.isHub) fleet);
              len = builtins.length hubNames;
              # small loop to find hub position among other hubs
              findIdx =
                i:
                if i >= len then
                  0
                else if builtins.elemAt hubNames i == _name then
                  i
                else
                  findIdx (i + 1);
              idx = findIdx 0;

              # each hub gets a progressively broader prefix: /24, /23, /22, ...
              # WARNING this solution is NOT scalable, and will only work with the first 8 hubs !!
              # TODO find a better way to have failovers
              rawBits = 24 - idx;
              cidrBits = if rawBits < 16 then 16 else rawBits;
            in
            [ "10.100.0.0/${toString cidrBits}" ];
        in
        {
          publicKey = data.pubkey;
          allowedIPs = (if toHub then spokeAllowedIPs else [ ]) ++ [ "${data.ip}/32" ];
          endpoint = if data ? endpoint then "${data.endpoint}:${toString port}" else null;

          # Keepalives work spoke2hub and hub2hub (to keep punching NATs between hubs).
          persistentKeepalive = mkIf (data.isHub) 25;
        }
      ) (filterAttrs (n: d: n != config.networking.hostName && (thisNode.isHub || d.isHub)) fleet);
    };
  };
}
