# Stalwart mail relay, send-only
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types optionals;
  cfg = config.modules.services.stalwart;
  hostName = config.networking.hostName;
  certDir = config.security.acme.certs.${cfg.domain}.directory;
  credPath = "/run/credentials/stalwart.service";

  # adminHost = "stalwart.${hostName}.${cfg.domain}";
  adminHost = mailHost;
  mailHost = "mail.${hostName}.${cfg.domain}";

  # utils for config
  ifthen = field: data: {
    "if" = field;
    "then" = data;
  };
  otherwise = value: { "else" = value; };
in
{
  options.modules.services.stalwart = {
    enable = mkEnableOption "Stalwart SMTP (send-only, direct MX)";

    domain = mkOption {
      type = types.str;
      default = "andrecadete.com";
      description = "Domain used for sending mail. Requires a wildcard ACME cert for this domain.";
    };
  };

  config = mkIf cfg.enable {
    services.stalwart = {
      enable = true;
      stateVersion = "26.05";
      openFirewall = true;

      credentials = {
        "cert.pem" = "${certDir}/fullchain.pem";
        "key.pem" = "${certDir}/key.pem";
        "oci-user" = config.age.secrets.ociSmtpUser.path;
        "oci-pass" = config.age.secrets.ociSmtpPass.path;
      };

      settings = {
        # verbose logs
        tracer.console = {
          enable = true;
          type = "console";
          level = "trace";
        };
        config.local-keys = [
          "certificate.*"
          "cluster.node-id"
          "directory.*"
          "lookup.default.domain"
          "lookup.default.hostname"
          "metrics.*"
          "queue.route.*"
          "queue.strategy.route.*"
          "report.analysis.*"
          "resolver.*"
          "server.*"
          "!server.blocked-ip.*"
          "session.mta-sts.*"
          "session.rcpt.catch-all"
          "session.rcpt.rewrite.*"
          "spam-filter.resource"
          "storage.blob"
          "storage.data"
          "storage.directory"
          "storage.fts"
          "storage.lookup"
          "store.*"
          "tracer.*"
          "webadmin.*"
        ];

        # TLS certificate shared with nginx
        certificate.default = {
          cert = "%{file:${credPath}/cert.pem}%";
          private-key = "%{file:${credPath}/key.pem}%";
          default = true;
        };

        lookup.default = {
          domain = cfg.domain;
          hostname = mailHost;
        };

        # oracle cloud email delivery
        queue.route.oci = {
          type = "relay";
          address = "smtp.email.eu-madrid-1.oci.oraclecloud.com"; # eu-madrid-1
          port = 587;
          protocol = "smtp";
          tls = {
            implicit = true;
          };
          auth = {
            username = "%{file:${credPath}/oci-user}%";
            password = "%{file:${credPath}/oci-pass}%";
          };
        };

        # local mail
        
        strategy.route = [
          (ifthen "is_local_domain('', rcpt_domain)" "'local'")
          # sometimes spf reports are sent to mail.<domain> instead, which is not registered as a local domain
          (ifthen "rcpt_domain == 'mail.${cfg.domain}'" "'local'")
          # use oci when my domains are sending
          (ifthen "sender_domain == '${cfg.domain}'" "'oci'")
          (otherwise "'mx'")
        ];

        # no relay
        # queue.route.mx = {
        #   type = "mx";
        #   ip-lookup = "ipv4_then_ipv6";
        #   limits = {
        #     mx = 5;
        #     multihomed = 2;
        #   };
        # };

        # SMTP submission (client auth) + admin HTTP behind nginx, loopback only
        server.listener = {
          submission = {
            bind = [ "[::]:${toString lib.my.ports.smtpSubmission}" ];
            protocol = "smtp";
          };
          submissions = {
            bind = [ "[::]:${toString lib.my.ports.smtpSubmissionTls}" ];
            protocol = "smtp";
            tls.implicit = true;
          };
          http = {
            bind = [ "127.0.0.1:${toString lib.my.ports.stalwartHttp}" ];
            protocol = "http";
            url = "https://${adminHost}";
            use-x-forwarded = true;
          };
        };
        # admin creds - deprecated
        authentication.fallback-admin = {
          user = "admin";
          secret = "%{file:${credPath}/admin-pass}%";
        };
      };
    };

    age.secrets.ociSmtpUser = {
      file = secrets.host.ociSmtpUser;
      owner = "stalwart";
    };
    age.secrets.ociSmtpPass = {
      file = secrets.host.ociSmtpPass;
      owner = "stalwart";
    };
    age.secrets.stalwartAdminEnv = {
      file = secrets.host.stalwartAdminEnv;
      owner = "stalwart";
    };

    systemd.services.stalwart = {
      wants = [ "acme-${cfg.domain}.service" ];
      after = [ "acme-${cfg.domain}.service" ];
      serviceConfig.EnvironmentFile = config.age.secrets.stalwartAdminEnv.path;
    };

    # Restart stalwart on certificate renewal
    security.acme.certs.${cfg.domain}.reloadServices =
      optionals config.modules.services.nginx.enable [ "stalwart.service" ];

    # Expose the admin UI behind nginx with the existing wildcard cert
    modules.services.nginx.exposedServices =
      optionals config.modules.services.nginx.enable [
        {
          serverName = adminHost;
          port = lib.my.ports.stalwartHttp;
          acmeHost = "${config.networking.hostName}.andrecadete.com";
        }
      ];
  };
}