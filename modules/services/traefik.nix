# Traefik edge proxy
# terminates TLS on 80/443
# routes docker containers by their labels and hands every other host to nginx (plain HTTP on loopback)
#
# A docker compose service is exposed with:
#   labels:
#     - traefik.enable=true
#     - traefik.http.routers.<unique name>.rule=Host('sub.andrecadete.com')
#     - traefik.http.services.<unique name>.loadbalancer.server.port=<container port>
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    attrValues
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.modules.services.traefik;

  # exposedServices -> one websecure router + service each, named after the host
  exposedName = entry: "nix-" + lib.replaceStrings [ "." ] [ "-" ] entry.serverName;
  exposedRouters = lib.listToAttrs (
    map (
      entry:
      lib.nameValuePair (exposedName entry) {
        rule = "Host(`${entry.serverName}`)";
        entryPoints = [ "websecure" ];
        service = exposedName entry;
      }
    ) cfg.exposedServices
  );
  exposedBackends = lib.listToAttrs (
    map (
      entry:
      lib.nameValuePair (exposedName entry) {
        loadBalancer.servers = [ { url = "http://127.0.0.1:${toString entry.port}"; } ];
      }
    ) cfg.exposedServices
  );

  # basically every docker router's Host('...') as a prometheus http_sd target list
  targetsDir = "/var/lib/traefik-blackbox-targets";
  generateTargets = pkgs.writeShellApplication {
    name = "traefik-blackbox-targets";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
    ];
    text = ''
      tmp=$(mktemp "${targetsDir}/.targets.XXXXXX")
      trap 'rm -f "$tmp"' EXIT

      # on failure the previous list stays in place
      # retries cover traefik still starting
      curl -fsS --max-time 10 --retry 10 --retry-delay 2 --retry-connrefused "http://127.0.0.1:${toString lib.my.ports.traefikApi}/api/http/routers?per_page=10000" \
        | jq '
            [ .[] | select(.provider == "docker") | .rule
              | scan("Host\\(`([^`]+)`\\)") | .[0] ]
            | unique
            | map({ targets: ["https://\(.)"], labels: { alias: . } })
          ' > "$tmp"

      chmod 0640 "$tmp"
      mv "$tmp" "${targetsDir}/targets.json"
    '';
  };

  certFiles = name: {
    certFile = "${config.security.acme.certs.${name}.directory}/fullchain.pem";
    keyFile = "${config.security.acme.certs.${name}.directory}/key.pem";
  };
  acmeCertNames = attrNames config.security.acme.certs;

  logDir = "/var/log/traefik";

  # cloudflared connects from loopback and sets X-Forwarded-{Proto,For}
  trustedIPs = [
    "127.0.0.1/32"
    "::1/128"
  ];
in
{
  options.modules.services.traefik = {
    enable = mkEnableOption "traefik edge proxy (docker provider, nginx fallback)";

    defaultCert = mkOption {
      type = types.str;
      default = "andrecadete.com";
      description = "Name of the provisioned certificate presented to unknown SNI names.";
    };

    exposedServices = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            serverName = mkOption {
              type = types.str;
              description = "Host to route through traefik";
            };

            port = mkOption {
              type = types.port;
              description = "Local TCP port of the service behind traefik.";
            };
          };
        }
      );
      default = [ ];
      description = "Host -> local port routes";
    };

    blackboxTargets.enable = mkEnableOption "publishing every docker router's Host('...') to the fleet as prometheus http_sd blackbox targets";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = config.modules.services.nginx.enable;
          message = "modules.services.traefik requires modules.services.nginx (fallback backend and ACME certs).";
        }
      ];

      services.traefik = {
        enable = true;

        staticConfigOptions = {
          global = {
            checkNewVersion = false;
            sendAnonymousUsage = false;
          };
          log.level = "WARN";
          accessLog = {
            filePath = "${logDir}/access.log";
            format = "json";
            fields = {
              defaultMode = "keep";
              headers = {
                defaultMode = "drop";
                names = {
                  "User-Agent" = "keep";
                  "Referer" = "keep";
                  "Cf-Connecting-Ip" = "keep";
                };
              };
            };
          };

          entryPoints = {
            web = {
              address = ":${toString lib.my.ports.http}";
              forwardedHeaders = { inherit trustedIPs; };
            };
            websecure = {
              address = ":${toString lib.my.ports.https}";
              # docker routers without an explicit entrypoint land here, with TLS
              asDefault = true;
              http = {
                tls = { };
                # cloudflared forwards plain HTTP visitors here with X-Forwarded-Proto: http
                middlewares = [ "https-redirect@file" ];
              };
              forwardedHeaders = { inherit trustedIPs; };
            };
          };

          providers.docker = {
            exposedByDefault = false;
          };
        };

        dynamicConfigOptions = {
          tls = {
            certificates = map certFiles acmeCertNames;
            stores.default.defaultCertificate = certFiles cfg.defaultCert;
          };

          # Lowest priority catch-all: anything not claimed by a docker label goes to nginx, which decides whether to redirect to HTTPS (X-Forwarded-Proto) or serve
          # Docker routers are websecure-only
          http = {
            # X-Forwarded-Proto
            middlewares.https-redirect.redirectScheme = {
              scheme = "https";
              permanent = true;
            };
            routers = {
              nginx-web = {
                rule = "PathPrefix(`/`)";
                priority = 1;
                entryPoints = [ "web" ];
                service = "nginx";
              };
              nginx-websecure = {
                rule = "PathPrefix(`/`)";
                priority = 1;
                entryPoints = [ "websecure" ];
                service = "nginx";
              };
            }
            // exposedRouters;
            services = {
              nginx.loadBalancer.servers = [
                { url = "http://127.0.0.1:${toString lib.my.ports.nginxBackend}"; }
              ];
            }
            // exposedBackends;
          };
        };
      };

      # read the socket for the docker provider (privilege escalation?)
      users.users.traefik.extraGroups = [ "docker" ];

      systemd.services.traefik = {
        wants = map (name: "acme-${name}.service") acmeCertNames;
        after = [ "docker.service" ] ++ map (name: "acme-${name}.service") acmeCertNames;
        serviceConfig = {
          LogsDirectory = "traefik";
          LogsDirectoryMode = "0750";
        };
      };

      # traefik reopens its access log on USR1
      services.logrotate.settings.traefik = {
        files = "${logDir}/*.log";
        su = "traefik traefik";
        frequency = "daily";
        rotate = -1;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
        postrotate = "systemctl kill --signal=USR1 --kill-whom=main traefik.service";
      };
    }

    # blackbox targets
    (mkIf cfg.blackboxTargets.enable {
      services.traefik = {
        staticConfigOptions = {
          # read-only api without a dashboard
          api.dashboard = false;
          entryPoints.traefik-api.address = "127.0.0.1:${toString lib.my.ports.traefikApi}";
        };
        dynamicConfigOptions.http.routers.api = {
          rule = "PathPrefix(`/api`)";
          entryPoints = [ "traefik-api" ];
          service = "api@internal";
          # polled every minute by traefik-blackbox-targets, so fuget bout logs
          observability.accessLogs = false;
        };
      };

      systemd.services.traefik-blackbox-targets = {
        description = "Export traefik docker routers as blackbox targets";
        after = [ "traefik.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe generateTargets;
          User = "nginx";
          Group = "nginx";
          StateDirectory = baseNameOf targetsDir;
          StateDirectoryMode = "0750";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
        };
      };
      systemd.timers.traefik-blackbox-targets = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "1min";
        };
      };

      services.nginx.virtualHosts.blackbox-traefik-targets = {
        serverName = "_";
        listen = [
          {
            addr = "0.0.0.0";
            port = lib.my.ports.blackboxTraefikTargets;
          }
        ];
        extraConfig = ''
          access_log off;
        ''
        # reachable only through uptimeWire0 from fleet members
        + lib.concatMapStrings (host: "allow ${host.ip};\n") (attrValues lib.my.uptimewire.fleet)
        + ''
          deny all;
        '';
        locations."= /targets.json".alias = "${targetsDir}/targets.json";
      };
      networking.firewall.interfaces.uptimeWire0.allowedTCPPorts = [
        lib.my.ports.blackboxTraefikTargets
      ];
    })
  ]);
}
