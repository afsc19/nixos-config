# Traefik edge proxy: terminates TLS on 80/443, routes docker containers by their
# labels and hands every other host to nginx (plain HTTP on loopback).
#
# A docker compose service is exposed with:
#   labels:
#     - traefik.enable=true
#     - traefik.http.routers.<unique name>.rule=Host(`sub.andrecadete.com`)
#     - traefik.http.services.<unique name>.loadbalancer.server.port=<container port>
# Hostnames live in the compose files (outside this repo), so they stay private.
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    attrNames
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.modules.services.traefik;

  certFiles = name: {
    certFile = "${config.security.acme.certs.${name}.directory}/fullchain.pem";
    keyFile = "${config.security.acme.certs.${name}.directory}/key.pem";
  };
  acmeCertNames = attrNames config.security.acme.certs;

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
  };

  config = mkIf cfg.enable {
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
        accessLog = { };

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
        # Docker routers are websecure-only, so on port 80 they also reach nginx's default server, which upgrades them to HTTPS
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
          };
          services.nginx.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString lib.my.ports.nginxBackend}"; }
          ];
        };
      };
    };

    # docker: read the socket for the docker provider (root-equivalent access)
    users.users.traefik.extraGroups = [ "docker" ];

    systemd.services.traefik = {
      wants = map (name: "acme-${name}.service") acmeCertNames;
      after = [ "docker.service" ] ++ map (name: "acme-${name}.service") acmeCertNames;
    };
  };
}
