# pairdrop, peer to peer file transfers, routed by traefik
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

  cfg = config.modules.services.pairdrop;
  port = lib.my.ports.pairdrop;
  coturn = config.modules.services.coturn;
  turnHost = "${coturn.domain}:${toString coturn.port}";

  secretsDir = "/var/lib/pairdrop-secrets";
  generatedFile = "${secretsDir}/secrets.env";
  envFile = if cfg.unlockEnvFile != null then cfg.unlockEnvFile else generatedFile;
in
{
  options.modules.services.pairdrop = {
    enable = mkEnableOption "pairdrop";
    domain = mkOption {
      type = types.str;
      default = "drop.andrecadete.com";
      description = "Public hostname of pairdrop, routed by traefik";
    };
    stunServers = mkOption {
      type = types.listOf types.str;
      default = [ "stun:stun.cloudflare.com:3478" ];
      description = "Public stun servers handed to the browsers, our own coturn is always added as a backup when it is enabled";
    };
    unlockEnvFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/agenix/pairdropEnv";
      description = ''
        Env file containing UNLOCK_KEY=<password>, a random one is generated into ${generatedFile} when null.
        Only browsers that entered it at /unlock get the turn servers and the websocket fallback, see pairdrop-unlock.patch.
      '';
    };
    trustedProxies = mkOption {
      type = types.ints.unsigned;
      default = 2;
      description = "Proxy hops in front of pairdrop, it pairs devices by client ip, 2 covers cloudflared and traefik";
    };
  };

  config = mkIf cfg.enable {
    services.pairdrop = {
      enable = true;
      inherit port;
      # adds the /unlock page, without UNLOCK_KEY it behaves like upstream
      package = pkgs.pairdrop.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./pairdrop-unlock.patch ];
      });

      rtcConfig = {
        sdpSemantics = "unified-plan";
        iceServers =
          map (url: { urls = url; }) cfg.stunServers
          # own host as a backup for both stun and turn
          ++ lib.optional coturn.enable {
            urls = [
              "stun:${turnHost}"
              "turn:${turnHost}?transport=udp"
              "turn:${turnHost}?transport=tcp"
            ];
            username = coturn.username;
            credential = coturn.password;
          };
      };
      environment = {
        RATE_LIMIT = cfg.trustedProxies;
        IPV6_LOCALIZE = 4;
        WS_FALLBACK = true;

        DONATION_BUTTON_ACTIVE = false;
        TWITTER_BUTTON_ACTIVE = false;
        MASTODON_BUTTON_ACTIVE = false;
        BLUESKY_BUTTON_ACTIVE = false;
        CUSTOM_BUTTON_ACTIVE = false;
        PRIVACYPOLICY_BUTTON_ACTIVE = false;
      };
    };

    systemd.services.pairdrop = {
      serviceConfig.EnvironmentFile = envFile;
    }
    // lib.optionalAttrs (cfg.unlockEnvFile == null) {
      requires = [ "pairdrop-secrets.service" ];
      after = [ "pairdrop-secrets.service" ];
    };

    # without unlockEnvFile the password is generated once, read it with: sudo cat ${generatedFile}
    systemd.services.pairdrop-secrets = mkIf (cfg.unlockEnvFile == null) {
      description = "Generate the pairdrop unlock password";
      wantedBy = [ "multi-user.target" ];
      before = [ "pairdrop.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "pairdrop-secrets";
        StateDirectoryMode = "0700";
        UMask = "0077";
      };
      script = ''
        if [ ! -f ${generatedFile} ]; then
          printf 'UNLOCK_KEY=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 12)" > ${generatedFile}
        fi
      '';
    };

    modules.services.traefik.exposedServices = mkIf config.modules.services.traefik.enable [
      {
        serverName = cfg.domain;
        inherit port;
      }
    ];

    modules.services.monitor.blackboxEndpoints = [
      {
        alias = "pairdrop";
        url = "https://${cfg.domain}";
      }
    ];
  };
}
