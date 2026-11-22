# A CrowdSec as an Intrusion Prevention System (IPS) configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    optionals
    ;

  cfg = lib.my.uptimewire.fleet."${config.networking.hostName}".crowdsec;
  nginxEnabled = config.modules.services.nginx.enable;
  traefikEnabled = config.modules.services.traefik.enable;
  traefikBouncerKeyFile = config.modules.services.traefik.crowdsec.lapiKeyFile;
in
{
  # Crowdsec is now declared in the uptimewire fleet
  # options.modules.services.ipsec.crowdsec.enable = mkEnableOption "CrowdSec IPS";

  config = mkIf cfg {
    # error fixing
    systemd.tmpfiles.rules = [
      "d /var/lib/crowdsec 0750 crowdsec crowdsec - -"
      "f /var/lib/crowdsec/online_api_credentials.yaml 0640 crowdsec crowdsec - -"
    ]
    ++ optionals traefikEnabled [
      "d ${dirOf traefikBouncerKeyFile} 0750 root traefik - -"
    ];

    services.crowdsec = {
      enable = true;
      package = pkgs.unstable.crowdsec;

      # use LAPI
      settings = {
        general = {
          api.server = {
            enable = true;
            listen_uri = "127.0.0.1:${toString lib.my.ports.crowdsecLAPI}";
          };
          prometheus = {
            enabled = true;
            level = "full";
            listen_addr = "0.0.0.0";
            listen_port = lib.my.ports.prometheusCrowdsec;
          };
        };
        lapi.credentialsFile = "/var/lib/crowdsec/local_api_credentials.yaml";
        capi.credentialsFile = "/var/lib/crowdsec/online_api_credentials.yaml";
      };

      hub.collections = [
        "crowdsecurity/linux"
      ]
      ++ optionals nginxEnabled [
        "crowdsecurity/nginx"
      ]
      # appsec requests come from the traefik bouncer plugin
      ++ optionals traefikEnabled [
        "crowdsecurity/traefik"
        "crowdsecurity/appsec-virtual-patching"
        "crowdsecurity/appsec-generic-rules"
      ];

      localConfig = {
        acquisitions = [
          # always ssh
          {
            source = "journalctl";
            journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
            labels.type = "syslog";
          }
          {
            source = "appsec";
            listen_addr = "127.0.0.1:${toString lib.my.ports.crowdsecAppSec}";
            appsec_configs = [ "crowdsecurity/appsec-default" ];
            labels.type = "appsec";
          }
        ]
        ++ optionals nginxEnabled [
          # nginx if enabled
          {
            source = "file";
            filenames = [
              "/var/log/nginx/access.log"
              "/var/log/nginx/error.log"
            ];
            labels.type = "nginx";
          }
        ]
        ++ optionals traefikEnabled [
          {
            source = "file";
            filenames = [ "/var/log/traefik/access.log" ];
            labels.type = "traefik";
          }
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
      before = [ "crowdsec-firewall-bouncer.service" ];
      wantedBy = [ "crowdsec-firewall-bouncer.service" ];
      path = [
        pkgs.crowdsec
        pkgs.coreutils
      ];
      script = ''
        KEY_FILE="/var/lib/crowdsec/firewall-bouncer.key"
        BOUNCER_NAME="nixos-firewall-bouncer"

        CSCLI="/run/current-system/sw/bin/cscli"

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
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
    # same thing for the traefik bouncer plugin, the key lands where traefik can read it
    systemd.services.crowdsec-traefik-bouncer-setup = mkIf traefikEnabled {
      description = "Generate CrowdSec Traefik Bouncer API Key";
      wants = [ "crowdsec.service" ];
      after = [ "crowdsec.service" ];
      before = [ "traefik.service" ];
      wantedBy = [ "traefik.service" ];
      path = [ pkgs.coreutils ];
      script = ''
        KEY_FILE="${traefikBouncerKeyFile}"
        BOUNCER_NAME="nixos-traefik-bouncer"

        CSCLI="/run/current-system/sw/bin/cscli"

        if [ ! -s "$KEY_FILE" ]; then
          echo "generating traefik bouncer API key..."
          $CSCLI bouncers delete "$BOUNCER_NAME" 2>/dev/null || true

          API_KEY=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)
          $CSCLI bouncers add "$BOUNCER_NAME" -k "$API_KEY"
          echo "$API_KEY" > "$KEY_FILE"
          chmod 0440 "$KEY_FILE"
          chown root:traefik "$KEY_FILE"
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    # keep the lapi credentials url in sync with listen_uri
    systemd.services.crowdsec.serviceConfig.ExecStartPre = lib.mkAfter [
      (pkgs.writeShellScript "crowdsec-fix-lapi-url" ''
        CRED="${config.services.crowdsec.settings.lapi.credentialsFile}"
        WANT="url: http://${config.services.crowdsec.settings.general.api.server.listen_uri}/"

        if [ -s "$CRED" ] && ! ${pkgs.gnugrep}/bin/grep -qxF "$WANT" "$CRED"; then
          echo "pointing lapi credentials at the current listen_uri..."
          ${pkgs.gnused}/bin/sed -i "s|^url: .*|$WANT|" "$CRED"
        fi
      '')
    ];

    users.users.crowdsec.extraGroups =
      optionals nginxEnabled [ "nginx" ] ++ optionals traefikEnabled [ "traefik" ];

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

    # ctf challs are meant to be attacked, so their traffic never counts towards a ban
    environment.etc."crowdsec/parsers/s02-enrich/my-chall-whitelist.yaml".text = mkIf traefikEnabled ''
      name: my/whitelist-ctf-challs
      description: "Ignore requests to ctf challenges"
      whitelist:
        reason: "CTF challenge traffic"
        expression:
          - evt.Meta.target_fqdn endsWith ".chall.ctf.andrecadete.com"
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
