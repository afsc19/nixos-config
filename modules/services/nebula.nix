# nebula (VPN) configuration.
{
  config,
  lib,
  secrets,
  pkgs,
  ...
}:
let
  inherit (builtins) attrNames;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    ;
  cfg = config.modules.services.nebula;

  lighthouses = {
    "192.168.100.1" = [ "world.sylva.andrecadete.com:4242" ];
    "192.168.100.6" = [ "world.desolo.andrecadete.com:4242" ];
  };
in
{
  options.modules.services.nebula = {
    enable = mkEnableOption "nebula";
    isLighthouse = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node is a lighthouse.";
    };

    firewall.outbound = mkOption {
      type = types.listOf types.attrs;
      default = [
        {
          port = "any";
          proto = "any";
          host = "any";
        }
      ];
      description = lib.mdDoc "Firewall rules for outbound traffic.";
      example = [
        {
          port = "any";
          proto = "any";
          host = "any";
          # group = "afsc";
        }
      ];
    };
    firewall.inbound = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = lib.mdDoc "Firewall rules for inbound traffic.";
      example = [
        {
          port = "any";
          proto = "any";
          host = "any";
          # group = "afsc";
        }
      ];
    };
    firewall.allowPinging = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to allow ICMP pings to this node.";
    };
  };

  config = mkIf cfg.enable {
    # Automatically get nebula CA/cert/key from agenix
    age.secrets.nebulaCA = {
      file = secrets.nebulaCA;
      owner = "nebula-nebula0";
    };
    age.secrets.nebulaCert = {
      file = secrets.host.nebulaCert;
      owner = "nebula-nebula0";
    };
    age.secrets.nebulaKey = {
      file = secrets.host.nebulaKey;
      owner = "nebula-nebula0";
    };

    services.nebula.networks.nebula0 = {
      enable = true;
      ca = config.age.secrets.nebulaCA.path;
      cert = config.age.secrets.nebulaCert.path;
      key = config.age.secrets.nebulaKey.path;
      isLighthouse = cfg.isLighthouse;
      isRelay = cfg.isLighthouse; # assume all lighthouses are relays as well
      lighthouses = lib.lists.optionals (!cfg.isLighthouse) (attrNames lighthouses);
      # listen on both ipv4 and ipv6
      listen.host = "[::]";

      tun.device = "nebula.nebula0";

      firewall.outbound = [
        {
          port = "any";
          proto = "any";
          host = "any";
        }
      ]
      ++ cfg.firewall.outbound;
      firewall.inbound =
        (lib.lists.optional cfg.firewall.allowPinging {
          port = "any";
          proto = "icmp";
          host = "any";
        })
        ++ [
          {
            port = "any";
            proto = "any";
            group = "afsc";
          }
        ]
        ++ cfg.firewall.inbound;

      staticHostMap = lighthouses;

      settings = {
        # punch through firewall NATs
        punchy = {
          punch = true;
          respond = true;
        };

        static_map = {
          # fetch both A and AAAA DNS records for lighthouses
          network = "ip";
        };

        lighthouse = {
          local_allow_list = {
            interfaces = {
              # don't advertise docker IPs to lighthouse
              "docker.*" = false;
              "br-[0-9a-f]{12}" = false;
            };
          };
        };

        relay = {
          relays = lib.lists.optionals (!cfg.isLighthouse) (attrNames lighthouses);
          use_relays = !cfg.isLighthouse;
        };
      };
    };

    # nebula can't accept connections if it's blocked by iptables
    # therefore, for all port that isn't open on the firewall, open it for the nebula interface
    networking.firewall.interfaces.${config.services.nebula.networks.nebula0.tun.device} =
      let
        hasTcpAny = builtins.any (
          rule: (rule.proto or null == "tcp" || rule.proto or null == "any") && rule.port or null == "any"
        ) cfg.firewall.inbound;
        hasUdpAny = builtins.any (
          rule: (rule.proto or null == "udp" || rule.proto or null == "any") && rule.port or null == "any"
        ) cfg.firewall.inbound;
        tcpPorts = builtins.filter (
          rule:
          (rule.proto or null == "tcp" || rule.proto or null == "any")
          && (builtins.isInt (rule.port or null))
          && !(builtins.elem rule.port config.networking.firewall.allowedTCPPorts)
        ) cfg.firewall.inbound;
        udpPorts = builtins.filter (
          rule:
          (rule.proto or null == "udp" || rule.proto or null == "any")
          && (builtins.isInt (rule.port or null))
          && !(builtins.elem rule.port config.networking.firewall.allowedUDPPorts)
        ) cfg.firewall.inbound;

        getPorts = map (rule: rule.port);
        allPorts = [
          {
            from = 0;
            to = 65535;
          }
        ];
      in
      {
        allowedTCPPorts = if hasTcpAny then [ ] else getPorts tcpPorts;
        allowedUDPPorts = if hasUdpAny then [ ] else getPorts udpPorts;
        allowedTCPPortRanges = lib.lists.optionals hasTcpAny allPorts;
        allowedUDPPortRanges = lib.lists.optionals hasUdpAny allPorts;
      };

    # open port 4242 on the lighthouses, given that conntrack usually has a 30sec timeout and we want to keep connections alive.
    networking.firewall.allowedUDPPorts = lib.mkIf cfg.isLighthouse [ 4242 ];

    environment.systemPackages = with pkgs; [
      nebula
    ];
  };
}
