# Traefik edge proxy
# terminates TLS on 80/443
# routes docker containers by their labels and hands every other host to nginx (plain HTTP on loopback)
#
# Traefik has a single docker provider, so with both engines a second instance reads podman:
#   :443 edge (TLS, docker labels) -> fallback -> traefik-podman (loopback, podman labels) -> fallback -> nginx
#   :80  edge -> nginx, which upgrades unknown (container) hosts to HTTPS
# If traefik-podman is down, the edge falls back to nginx directly.
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
  secrets,
  ...
}:
let
  inherit (lib)
    attrNames
    attrValues
    hasAttrByPath
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    my
    ;
  cfg = config.modules.services.traefik;

  engines = {
    docker = {
      endpoint = "unix:///var/run/docker.sock";
      group = "docker";
      unit = "docker.service";
    };
    podman = {
      endpoint = "unix:///run/podman/podman.sock";
      group = "podman";
      unit = "podman.socket";
    };
  };
  enabledEngines = lib.filter (e: lib.elem e cfg.containerEngines) [
    "docker" # priority over podman just because
    "podman"
  ];
  edgeEngine = if enabledEngines == [ ] then null else engines.${lib.head enabledEngines};
  podmanInstance = lib.length enabledEngines == 2;

  toml = pkgs.formats.toml { };
  loopback = port: "http://127.0.0.1:${toString port}";

  podmanStatic = toml.generate "traefik-podman.toml" (
    lib.recursiveUpdate
      {
        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };
        log.level = "WARN";
        entryPoints = {
          # plain HTTP from the edge; named websecure so labels written for the edge still apply
          websecure = {
            address = "127.0.0.1:${toString lib.my.ports.traefikPodman}";
            asDefault = true;
            forwardedHeaders = { inherit trustedIPs; };
          };
          ping.address = "127.0.0.1:${toString lib.my.ports.traefikPodmanPing}"; # so it doesn't use websites' /ping
        };
        ping.entryPoint = "ping";
        providers.docker = {
          exposedByDefault = false;
          inherit (engines.podman) endpoint;
        };
        providers.file.filename = podmanDynamic;
      }
      (
        lib.optionalAttrs cfg.blackboxTargets.enable {
          api.dashboard = false;
          entryPoints.traefik-api.address = "127.0.0.1:${toString lib.my.ports.traefikPodmanApi}";
        }
      )
  );
  podmanDynamic = toml.generate "traefik-podman-dynamic.toml" {
    http = {
      routers = {
        nginx = {
          rule = "PathPrefix(`/`)";
          priority = 1;
          entryPoints = [ "websecure" ];
          service = "nginx";
        };
      }
      // lib.optionalAttrs cfg.blackboxTargets.enable {
        api = {
          rule = "PathPrefix(`/api`)";
          entryPoints = [ "traefik-api" ];
          service = "api@internal";
        };
      };
      services.nginx.loadBalancer.servers = [ { url = loopback lib.my.ports.nginxBackend; } ];
    };
  };

  # APIs polled for blackbox targets
  traefikApis = [
    (loopback lib.my.ports.traefikApi)
  ]
  ++ lib.optional podmanInstance (loopback lib.my.ports.traefikPodmanApi);

  # exposedServices -> one websecure router + service each, named after the host
  exposedName = entry: "nix-" + lib.replaceStrings [ "." ] [ "-" ] entry.serverName;
  exposedRouters = lib.listToAttrs (
    map (
      entry:
      lib.nameValuePair (exposedName entry) (
        {
          rule = "Host(`${entry.serverName}`)";
          entryPoints = [ "websecure" ];
          service = exposedName entry;
        }
        // lib.optionalAttrs (entry.nebulaOnly || entry.uptimewireOnly) {
          middlewares = [
            (
              if entry.nebulaOnly && entry.uptimewireOnly then
                "vpn-only"
              else if entry.nebulaOnly then
                "nebula-only"
              else
                "uptimewire-only"
            )
          ];
        }
      )
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
      # one api when there's no podman instance, so the loop is fine
      # shellcheck disable=SC2043
      for api in ${lib.escapeShellArgs traefikApis}; do
        curl -fsS --max-time 10 --retry 10 --retry-delay 2 --retry-connrefused "$api/api/http/routers?per_page=10000"
      done \
        | jq -s '
            [ .[][] | select(.provider == "docker") | .rule
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

  hasDashboardSecret = hasAttrByPath [ "host" "traefikDashboardAuth" ] secrets;

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

            nebulaOnly = mkOption {
              type = types.bool;
              default = false;
              description = "Restrict access to Nebula VPN IPs only.";
            };

            uptimewireOnly = mkOption {
              type = types.bool;
              default = false;
              description = "Restrict access to UptimeWire VPN IPs only.";
            };
          };
        }
      );
      default = [ ];
      description = "Host -> local port routes";
    };

    dashboard = {
      enable = mkEnableOption "traefik dashboard and API";

      hosts = mkOption {
        type = types.attrsOf (
          types.submodule {
            options.access = mkOption {
              type = types.enum [
                "nebula"
                "uptimewire"
                "vpn-only"
                "public"
              ];
              description = "Who may reach this host.";
            };
          }
        );
        default = {
          "traefik.${config.networking.hostName}.andrecadete.com".access = "nebula";
          "traefik.uptime.${config.networking.hostName}.andrecadete.com".access = "uptimewire";
        }
        // lib.optionalAttrs (config.networking.hostName == lib.my.uptimewire.captain) {
          "traefik.andrecadete.com".access = "public";
        };
        description = "Hosts serving the dashboard and who can reach them.";
      };
    };

    blackboxTargets.enable = mkEnableOption "publishing every docker router's Host('...') to the fleet as prometheus http_sd blackbox targets";

    containerEngines = mkOption {
      type = types.listOf (
        types.enum [
          "docker"
          "podman"
        ]
      );
      default = lib.filter (e: config.virtualisation.${e}.enable) [
        "docker"
        "podman"
      ];
      defaultText = lib.literalExpression "every engine with virtualisation.<engine>.enable";
      description = ''
        Container engines whose traefik labels are routed (podman through its docker-compatible API).
        With both, a second traefik instance reads podman behind the edge one.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = config.modules.services.nginx.enable;
          message = "modules.services.traefik requires modules.services.nginx (fallback backend and ACME certs).";
        }
      ]
      ++ lib.optional cfg.dashboard.enable {
        assertion = hasDashboardSecret;
        message = "modules.services.traefik.dashboard needs the traefikDashboardAuth secret (htpasswd line) for this host.";
      }
      ++ map (e: {
        assertion = config.virtualisation.${e}.enable;
        message = "modules.services.traefik.containerEngines contains ${e}, but virtualisation.${e} is disabled.";
      }) enabledEngines;

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

          providers.docker = mkIf (edgeEngine != null) {
            exposedByDefault = false;
            inherit (edgeEngine) endpoint;
          };
        }
        // lib.optionalAttrs cfg.dashboard.enable { api.dashboard = true; };

        dynamicConfigOptions = {
          tls = {
            certificates = map certFiles acmeCertNames;
            stores.default.defaultCertificate = certFiles cfg.defaultCert;
          };

          # Lowest priority catch-all: anything not claimed by a docker label goes to nginx, which decides whether to redirect to HTTPS (X-Forwarded-Proto) or serve
          # Docker routers are websecure-only
          http = {
            # X-Forwarded-Proto
            middlewares = {
              https-redirect.redirectScheme = {
                scheme = "https";
                permanent = true;
              };
              nebula-only.ipAllowList.sourceRange = [
                "192.168.100.0/24"
                "127.0.0.1/32"
                "::1/128"
              ];
              uptimewire-only.ipAllowList.sourceRange = [
                lib.my.uptimewire.cdir
                "127.0.0.1/32"
                "::1/128"
              ];
              vpn-only.ipAllowList.sourceRange = [
                "192.168.100.0/24"
                lib.my.uptimewire.cdir
                "127.0.0.1/32"
                "::1/128"
              ];
            }
            // lib.optionalAttrs cfg.dashboard.enable {
              traefik-dashboard-auth.basicAuth = {
                usersFile = config.age.secrets.traefikDashboardAuth.path;
                removeHeader = true;
              };
              # the dashboard only lives under /dashboard/
              traefik-dashboard-root.redirectRegex = {
                regex = "^(https?://[^/]+)/?$";
                replacement = "$1/dashboard/";
              };
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
                service = if podmanInstance then "podman-or-nginx" else "nginx";
              };
            }
            // exposedRouters
            // lib.optionalAttrs cfg.dashboard.enable (
              lib.mapAttrs' (
                host: { access }:
                lib.nameValuePair ("traefik-dashboard-" + lib.replaceStrings [ "." ] [ "-" ] host) {
                  rule = "Host(`${host}`)";
                  entryPoints = [ "websecure" ];
                  service = "api@internal";
                  # ip check first, then auth, so nothing leaks to anonymous visitors
                  middlewares =
                    lib.optional (access == "nebula") "nebula-only"
                    ++ lib.optional (access == "uptimewire") "uptimewire-only"
                    ++ lib.optional (access == "vpn-only") "vpn-only"
                    ++ [
                      "traefik-dashboard-auth"
                      "traefik-dashboard-root"
                    ];
                }
              ) cfg.dashboard.hosts
            );
            services = {
              nginx.loadBalancer.servers = [ { url = loopback lib.my.ports.nginxBackend; } ];
            }
            // lib.optionalAttrs podmanInstance {
              traefik-podman.loadBalancer = {
                servers = [ { url = loopback lib.my.ports.traefikPodman; } ];
                healthCheck = {
                  path = "/ping";
                  port = lib.my.ports.traefikPodmanPing; # so it doesn't use websites' /ping
                  interval = "5s";
                  timeout = "2s";
                };
              };
              podman-or-nginx.failover = {
                service = "traefik-podman";
                fallback = "nginx";
              };
            }
            // exposedBackends;
          };
        };
      };

      networking.firewall.interfaces.uptimeWire0.allowedTCPPorts =
        lib.optional
          (
            (cfg.dashboard.enable && lib.any (h: h.access == "uptimewire" || h.access == "vpn-only") (attrValues cfg.dashboard.hosts))
            || lib.any (e: e.uptimewireOnly) cfg.exposedServices
          )
          lib.my.ports.https;

      age.secrets.traefikDashboardAuth = mkIf cfg.dashboard.enable {
        file = secrets.host.traefikDashboardAuth;
        owner = "traefik";
        group = "traefik";
        mode = "0400";
      };

      systemd.services.traefik = {
        wants =
          lib.optional (edgeEngine != null) edgeEngine.unit
          ++ map (name: "acme-${name}.service") acmeCertNames;
        after =
          lib.optional (edgeEngine != null) edgeEngine.unit
          ++ map (name: "acme-${name}.service") acmeCertNames;
        serviceConfig = {
          LogsDirectory = "traefik";
          LogsDirectoryMode = "0750";
          # read the engine's API socket for the docker/podman provider (privilege escalation?)
          # per unit, so each instance only reaches its own engine
          SupplementaryGroups = lib.optional (edgeEngine != null) edgeEngine.group;
        };
      };

      # podman labels
      systemd.services.traefik-podman = mkIf podmanInstance {
        description = "Traefik for podman containers, behind the edge traefik";
        wantedBy = [ "multi-user.target" ];
        wants = [
          "network-online.target"
          engines.podman.unit
        ];
        after = [
          "network-online.target"
          engines.podman.unit
        ];
        startLimitIntervalSec = 86400;
        startLimitBurst = 5;
        serviceConfig = {
          ExecStart = "${config.services.traefik.package}/bin/traefik --configfile=${podmanStatic}";
          User = "traefik";
          Group = "traefik";
          SupplementaryGroups = [ engines.podman.group ];
          Restart = "on-failure";
          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectHome = true;
          ProtectSystem = "full";
          RuntimeDirectory = "traefik-podman";
          WorkingDirectory = "/run/traefik-podman";
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
          api.dashboard = lib.mkDefault false;
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
