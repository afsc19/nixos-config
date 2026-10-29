{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  inherit (lib)
    elem
    hasAttrByPath
    listToAttrs
    map
    optionalAttrs
    mkEnableOption
    mkAfter
    mkBefore
    mkIf
    mkOption
    types
    mkMerge
    ;
  cfg = config.modules.services.nginx;
  hasEncryptedVhostsSecret = hasAttrByPath [ "host" "nginxVhosts" ] secrets;

  # Cloudflare tunnel tells the proto using X-Forwarded-Proto header
  forwardedProtoRedirect = pkgs.writeText "nginx-forwarded-proto-redirect.conf" ''
    if ($http_x_forwarded_proto = "http") {
      return 301 https://$host$request_uri;
    }
  '';

  vhosts = listToAttrs (
    map (entry: {
      name = entry.serverName;
      value = {
        # enableACME = true;
        useACMEHost = entry.acmeHost;
        forceSSL = true;

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
    map
      (cert: {
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
      })
      (
        cfg.acmeCerts
        ++ [
          {
            domain = "${config.networking.hostName}.andrecadete.com";
            extraDomainNames = [ "*.${config.networking.hostName}.andrecadete.com" ];
            dnsProvider = "cloudflare";
          }
        ]
      )
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

    httpRedirect.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Catch-all default server on port 80 (HTTP -> HTTPS redirect, or static root if set)";
    };

    httpRedirect.root = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Static root served by the port 80 default server. Defaults to HTTP -> HTTPS redirection.";
    };

    forwardedProtoRedirect.enable = mkOption {
      type = types.bool;
      default = true;
      description = "cloudflare tunnel Catch-all HTTP -> HTTPS redirect (default server on port 80)";
    };

    dropUnknownTls = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Drop (444) HTTPS requests for hosts that match no server block (default server on port 443).";
      };

      acmeHost = mkOption {
        type = types.str;
        default = "andrecadete.com";
        description = "Name of the provisioned certificate presented to unknown hosts.";
      };
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

  # extend every vhost (also ones declared by other modules) with the redirect snippet
  options.services.nginx.virtualHosts = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          config.extraConfig = mkIf (
            cfg.enable
            && cfg.forwardedProtoRedirect.enable
            && !(elem name [
              "_"
              "_tls"
            ])
          ) (mkBefore "include ${forwardedProtoRedirect};");
        }
      )
    );
  };

  config = mkIf cfg.enable {
    modules.services.nebula.firewall.inbound =
      map
        (port: {
          inherit port;
          proto = "tcp";
          group = "uptime";
        })
        (with lib.my.ports; [
          http
          https
        ]);

    age.secrets.nginxVhosts = mkIf (hasEncryptedVhostsSecret) {
      file = secrets.host.nginxVhosts;
      owner = "nginx";
      group = "nginx";
      mode = "0440";
    };

    services.nginx.enableReload = true;

    environment.etc."nginx/forwarded-proto-redirect.conf" = mkIf cfg.forwardedProtoRedirect.enable {
      source = forwardedProtoRedirect;
    };

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

      virtualHosts =
        vhosts
        // optionalAttrs cfg.httpRedirect.enable {
          # Port 80 default server for any host not handled by another port 80 server.
          # Serves a static root if configured, otherwise redirects HTTP -> HTTPS.
          "_" = {
            default = true;
            listen = [
              {
                addr = "0.0.0.0";
                port = 80;
              }
              {
                addr = "[::]";
                port = 80;
              }
            ];
            locations."/" =
              if cfg.httpRedirect.root != null then
                { root = cfg.httpRedirect.root; }
              else
                { return = "301 https://$host$request_uri"; };
          };
        }
        // optionalAttrs cfg.dropUnknownTls.enable {
          # Drop unknown TLS hosts after the handshake
          "_tls" = {
            serverName = "_";
            default = true;
            onlySSL = true;
            useACMEHost = cfg.dropUnknownTls.acmeHost;
            listen = [
              {
                addr = "0.0.0.0";
                port = 443;
                ssl = true;
              }
              {
                addr = "[::]";
                port = 443;
                ssl = true;
              }
            ];
            locations."/".return = "444";
          };
        };

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
