{
  config,
  lib,
  secrets,
  ...
}:
let
  inherit (lib)
    hasAttrByPath
    listToAttrs
    map
    optionalAttrs
    mkEnableOption
    mkAfter
    mkIf
    mkOption
    types
    mkMerge
    optionals
    ;
  cfg = config.modules.services.nginx;
  hasEncryptedVhostsSecret = hasAttrByPath [ "host" "nginxVhosts" ] secrets;

  vhosts = listToAttrs (
    map (entry: {
      name = entry.serverName;
      value = {
        # enableACME = true;
        useACMEHost = entry.acmeHost;
        forceSSL = true; # TODO build HTTP -> HTTPS redirection

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString entry.port}";
          proxyWebsockets = true;
        };
      }
      // optionalAttrs entry.nebulaOnly {
        extraConfig = ''
          allow 192.168.100.0/24;
          allow 127.0.0.1;
          allow ::1;
          deny all;
        '';
      };
    }) cfg.exposedServices
  );

  acmeCerts = listToAttrs (
    map (cert: {
      name = cert.domain;
      value = {
        group = "nginx";
      }
      // (optionalAttrs (cert.extraDomainNames != [ ]) {
        inherit (cert) extraDomainNames;
      })
      // (optionalAttrs (cert.dnsProvider != null) {
        inherit (cert) dnsProvider;
      });
    }) (cfg.acmeCerts ++
      [{
        domain = "${config.networking.hostName}.andrecadete.com";
        extraDomainNames = [ "*.${config.networking.hostName}.andrecadete.com" ];
        dnsProvider = "cloudflare";
      }])
  );
in
{
  options.modules.services.nginx = {
    enable = mkEnableOption "nginx reverse proxy";

    exposedServices = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            serverName = mkOption {
              type = types.str;
              description = "Subdomain to expose through nginx.";
            };

            port = mkOption {
              type = types.port;
              description = "Local TCP port of the service behind nginx.";
            };

            nebulaOnly = mkOption {
              type = types.bool;
              default = false;
              description = "Restrict access to Nebula VPN IPs only.";
            };

            acmeHost = mkOption {
              type = types.str;
              description = "Name of the provisioned certificate to use.";
            };
          };
        }
      );
      default = [ ];
      description = "List of subdomain -> local port mappings to expose via nginx.";
    };

    acmeCerts = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            domain = mkOption {
              type = types.str;
              description = "Primary ACME certificate domain.";
            };

            extraDomainNames = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Additional SAN names for the same certificate (such as wildcards).";
            };

            dnsProvider = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "ACME DNS provider name (required for wildcard certificates).";
            };
          };
        }
      );
      default = [ ];
      description = ''
        Public ACME certificates to provision in NixOS.
        Use `enableACME` directly if possible (unencrypted vhosts).
      '';
    };
  };

  config = mkIf cfg.enable {
    age.secrets.nginxVhosts = mkIf (hasEncryptedVhostsSecret) {
      file = secrets.host.nginxVhosts;
      owner = "nginx";
      group = "nginx";
      mode = "0440";
    };

    systemd.services.nginx.reloadIfChanged = true;

    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      # a custom log with the server name and cloudflared ip on access_custom.log
      # default on access.log
      commonHttpConfig = ''
        log_format vhost '$host $server_name $remote_addr / $http_cf_connecting_ip -- $remote_user [$time_local] '
                        '"$request" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent"';

        access_log /var/log/nginx/access.log combined;
        access_log /var/log/nginx/access_custom.log vhost;
      '';

      virtualHosts = vhosts;

      appendHttpConfig = mkMerge [
        (mkIf hasEncryptedVhostsSecret (mkAfter ''
          include ${config.age.secrets.nginxVhosts.path};
        ''))
        ''
          server {
            listen 127.0.0.1:${toString lib.my.ports.nginxStubStatus};
            server_name localhost;

            location = /stub_status {
              stub_status;
              allow 127.0.0.1;
              allow ::1;
              deny all;
            }
          }
        ''
      ];
    };

    users.users.nginx.extraGroups = [ "acme" ];

    # acme
    age.secrets.cloudflareDnsApiToken = {
      file = secrets.server.cloudflareDnsApiToken;
      owner = "acme";
      group = "acme";
      mode = "0400";
    };
    security.acme = {
      defaults = {
        email = "acme@andrecadete.com";
        environmentFile = config.age.secrets.cloudflareDnsApiToken.path;
      };
      acceptTerms = true;
      certs = acmeCerts;
    };

  };
}
