# A CrowdSec as an Intrusion Prevention System (IPS) configuration
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
    mkIf
    optionals
    ;

  cfg = config.modules.services.ipsec.crowdsec;
  nginxEnabled = config.modules.services.nginx.enable;
in
{
  options.modules.services.ipsec.crowdsec.enable = mkEnableOption "CrowdSec IPS";

  config = mkIf cfg.enable {
    # error fixing
    systemd.tmpfiles.rules =[
      "d /var/lib/crowdsec 0750 crowdsec crowdsec - -"
      "f /var/lib/crowdsec/online_api_credentials.yaml 0640 crowdsec crowdsec - -"
    ];


    services.crowdsec = {
      enable = true;
      package = pkgs.unstable.crowdsec;

      # use LAPI
      settings = {
        general.api.server = {
          enable = true;
          listen_uri = "127.0.0.1:8080";
        };
        lapi.credentialsFile = "/var/lib/crowdsec/local_api_credentials.yaml";
        capi.credentialsFile = "/var/lib/crowdsec/online_api_credentials.yaml";
      };

      hub.collections = [
        "crowdsecurity/linux"
      ] ++ optionals nginxEnabled [
        "crowdsecurity/nginx"
      ];

      localConfig = {
        acquisitions = [
          # always ssh
          { source = "journalctl"; journalctl_filter = [ "_SYSTEMD_UNIT=ssh.service" ]; labels.type = "syslog"; }
        ] ++ optionals nginxEnabled [
          # nginx if enabled
          { source = "file"; filenames = [ "/var/log/nginx/access.log" "/var/log/nginx/error.log" ]; labels.type = "nginx"; }
        ];
      };
    };

    services.crowdsec-firewall-bouncer = {
      enable = true;
      package = pkgs.unstable.crowdsec-firewall-bouncer;
      
      registerBouncer.enable = false;
      secrets.apiKeyPath = "/var/lib/crowdsec/firewall-bouncer.key";
    };

    # register the bouncer with a non-DynamicUser
    systemd.services.crowdsec-firewall-bouncer-setup = {
      description = "Generate CrowdSec Firewall Bouncer API Key";
      wants = [ "crowdsec.service" ];
      after = [ "crowdsec.service" ];
      before =[ "crowdsec-firewall-bouncer.service" ];
      wantedBy =[ "crowdsec-firewall-bouncer.service" ];
      path = [ pkgs.crowdsec pkgs.coreutils ];
      script = ''
        KEY_FILE="/var/lib/crowdsec/firewall-bouncer.key"
        BOUNCER_NAME="nixos-firewall-bouncer"

        CSCLI="${config.services.crowdsec.package}/bin/cscli"

        if [ ! -s "$KEY_FILE" ]; then
          echo "generating bouncer API key..."
          # stale database entries
          $CSCLI bouncers delete "$BOUNCER_NAME" 2>/dev/null || true
          
          API_KEY=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)
          $CSCLI bouncers add "$BOUNCER_NAME" -k "$API_KEY"
          echo "$API_KEY" > "$KEY_FILE"
          chmod 0400 "$KEY_FILE"
          chown crowdsec:crowdsec "$KEY_FILE"
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        RemainAfterExit = true;
      };
    };
    users.users.crowdsec.extraGroups = mkIf nginxEnabled [ "nginx" ];

    # prometheus
    systemd.services.crowdsec = {
      preStart = let
        # Define the port variable here for cleaner access
        prometheusPort = toString lib.my.ports.prometheusCrowdsec;
      in ''
        CONFIG_FILE="/etc/crowdsec/config.yaml"

        if ! grep -q "^prometheus:" "$CONFIG_FILE"; then
          echo "appending prometheus configuration to $CONFIG_FILE"
          cat <<EOF >> "$CONFIG_FILE"
prometheus:
  enabled: true
  level: full
  listen_addr: 127.0.0.1
  listen_port: ${prometheusPort}
EOF
        else
          # update port in case its needed
          echo "updating prometheus port in $CONFIG_FILE"
          sed -i "s/^  listen_port: .*/  listen_port: ${prometheusPort}/" "$CONFIG_FILE"
        fi
      '';
    };

    # Whitelist local IPs to prevent CrowdSec from banning the host itself xD
    environment.etc."crowdsec/parsers/s02-enrich/my-whitelist.yaml".text = ''
      name: my/whitelist-local
      description: "Whitelist local IPs to prevent self-banning"
      whitelist:
        reason: "Trust self crawling"
        ip:
          - "127.0.0.1"
          - "::1"
        cidr:
          - "10.0.0.0/8"
          - "172.16.0.0/12"
          - "192.168.0.0/16"
    '';

    # whitelist self's external ip (postoverflow stage) (checks right before ban)
    environment.etc."crowdsec/postoverflows/s01-whitelist/my-domain-whitelist.yaml".text = ''
      name: my/whitelist-domains
      description: "Whitelist self's external ip"
      whitelist:
        reason: "Trust self crawling"
        expression:
          # This does a DNS lookup of your domain and checks if the malicious IP matches it
          - evt.Overflow.Alert.Source.IP in LookupHost("world.${config.networking.hostName}.andrecadete.com")
    '';
  };
}



