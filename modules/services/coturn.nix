# coturn, a stun + turn server for webrtc apps (pairdrop)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modules.services.coturn;
  wired = config.my.networking.wiredInterface;
  relayRange = {
    from = cfg.minPort;
    to = cfg.maxPort;
  };
in
{
  options.modules.services.coturn = {
    enable = mkEnableOption "coturn stun and turn server";
    domain = mkOption {
      type = types.str;
      default = "world.${config.networking.hostName}.andrecadete.com";
      description = "Hostname clients connect to, has to be a DNS only record (the ddns module keeps this default one updated)";
    };
    externalIp = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "203.0.113.7";
      description = "Public ipv4 advertised for relayed traffic, resolved from domain when the service starts if null, so it never has to be written down here";
    };
    port = mkOption {
      type = types.port;
      default = 3478;
      description = "Stun and turn port, udp and tcp";
    };
    minPort = mkOption {
      type = types.port;
      default = 30000;
      description = "First port of the udp relay range";
    };
    maxPort = mkOption {
      type = types.port;
      default = 30099;
      description = "Last port of the udp relay range, one port per relayed connection";
    };
    username = mkOption {
      type = types.str;
      default = "pairdrop";
      description = "Turn username";
    };
    password = mkOption {
      type = types.str;
      default = "00a3ff84e4a717b66ce20dad99180b34";
      description = "Turn password, NOT a secret, pairdrop hands it to every browser that loads the page, so the limits below are what protect the relay";
    };
  };

  config = mkIf cfg.enable {
    services.coturn = {
      enable = true;
      listening-port = cfg.port;
      min-port = cfg.minPort;
      max-port = cfg.maxPort;
      realm = cfg.domain;
      lt-cred-mech = true;
      no-cli = true;
      # no certificates, so no turns:
      no-tls = true;
      no-dtls = true;
      extraConfig = ''
        user=${cfg.username}:${cfg.password}
        fingerprint
        no-multicast-peers

        # the credentials are public, so cap what one client and the whole relay can use
        user-quota=10
        total-quota=100
        # bytes per second for each session and for the whole relay, 3 MB/s all month is about 7.8 TB
        max-bps=2000000
        bps-capacity=3000000

        # never relay into this host's private side (docker, nebula, loopback, link local)
        denied-peer-ip=0.0.0.0-0.255.255.255
        denied-peer-ip=10.0.0.0-10.255.255.255
        denied-peer-ip=100.64.0.0-100.127.255.255
        denied-peer-ip=127.0.0.0-127.255.255.255
        denied-peer-ip=169.254.0.0-169.254.255.255
        denied-peer-ip=172.16.0.0-172.31.255.255
        denied-peer-ip=192.168.0.0-192.168.255.255
        denied-peer-ip=::1
        denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
      '';
    };

    # cloud hosts sit behind a 1:1 nat, so relayed traffic has to be advertised with the public ip
    # it is resolved from the (ddns kept) record on every start and only ever written to the runtime config
    systemd.services.coturn = {
      path = with pkgs; [
        getent
        gawk
        iproute2
      ];
      preStart = lib.mkAfter ''
        public=${if cfg.externalIp != null then lib.escapeShellArg cfg.externalIp else ""}
        if [ -z "$public" ]; then
          # the record can lag behind right after boot
          for _ in $(seq 1 30); do
            public=$(getent ahostsv4 ${cfg.domain} | awk 'NR==1 { print $1 }')
            [ -n "$public" ] && break
            sleep 2
          done
        fi
        if [ -z "$public" ]; then
          echo "coturn: could not resolve ${cfg.domain}, refusing to start with a wrong relay address" >&2
          exit 1
        fi

        private=$(ip -4 -o addr show dev ${wired} scope global | awk '{ split($4, a, "/"); print a[1]; exit }')
        if [ -n "$private" ] && [ "$private" != "$public" ]; then
          echo "external-ip=$public/$private" >> /run/coturn/turnserver.cfg
        else
          echo "external-ip=$public" >> /run/coturn/turnserver.cfg
        fi
      '';
    };

    # the oracle cloud security list also has to allow these
    networking.firewall.interfaces.${wired} = {
      allowedUDPPorts = [ cfg.port ];
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPortRanges = [ relayRange ];
    };
  };
}
