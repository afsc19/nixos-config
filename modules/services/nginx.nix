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
    ;
  cfg = config.modules.services.nginx;
  hasEncryptedVhostsSecret = hasAttrByPath [ "host" "nginxVhosts" ] secrets;

  vhosts = listToAttrs (
    map (entry: {
      name = entry.serverName;
      value = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString entry.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    }) cfg.exposedServices
  );

  acmeCerts = listToAttrs (
    map (cert: {
      name = cert.domain;
      value =
        {
          group = "nginx";
        }
        //
        (optionalAttrs (cert.extraDomainNames != [ ]) {
          inherit (cert) extraDomainNames;
        })
        // (optionalAttrs (cert.dnsProvider != null) {
          inherit (cert) dnsProvider;
        });
    }) cfg.acmeCerts
  );
in
{
  options.modules.services.nginx = {
    enable = mkEnableOption "nginx reverse proxy";

    useEncryptedVhosts = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Load additional nginx server blocks from the agenix secret `secrets/''${host}/nginxVhosts.age`.
        The decrypted file is included directly in nginx's http config.
      '';
    };

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
    assertions = [
      {
        assertion = !cfg.useEncryptedVhosts || hasEncryptedVhostsSecret;
        message = "modules.services.nginx.useEncryptedVhosts is enabled, but secrets.host.nginxVhosts is missing (expected secrets/<host>/nginxVhosts.age).";
      }
    ];

    age.secrets.nginxVhosts = mkIf (cfg.useEncryptedVhosts && hasEncryptedVhostsSecret) {
      file = secrets.host.nginxVhosts;
      owner = "nginx";
      group = "nginx";
      mode = "0440";
    };

    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      # Included server_name in the logs
      commonHttpConfig = ''
        log_format vhost '$host $server_name $remote_addr - $remote_user [$time_local] '
                        '"$request" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent"';
        access_log /var/log/nginx/access.log vhost;
      '';

      virtualHosts = vhosts;

      appendHttpConfig = mkMerge [
        (mkIf cfg.useEncryptedVhosts (
          mkAfter ''
            include ${config.age.secrets.nginxVhosts.path};
          ''
        ))
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

    security.acme = {
      acceptTerms = true;
      certs = acmeCerts;
    };
  };
}