# Prometheus configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    my
    mapAttrsToList
    optional
    mkDefault
    ;
  inherit (lib.my.uptimewire) fleet;
  inherit (lib.my.blackbox) ctfchalls;
  thisNode = fleet."${config.networking.hostName}" or null;
in
{
  config = mkMerge [
    # Enable Node Exporter on all fleet members
    (mkIf (thisNode != null) {
      services.prometheus.exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = lib.my.ports.prometheusExporter;
        };
        blackbox = mkIf thisNode.isHub {
          enable = mkDefault false;
          port = lib.my.ports.prometheusBlackbox;
          configFile = pkgs.writeText "blackbox.yml" ''
            modules:
              http_2xx:
                prober: http
                timeout: 5s
                http:
                  valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
                  valid_status_codes: []  # Defaults to 2xx
                  method: GET
          '';
        };

        # Only for devices running nginx
        nginx = mkIf config.services.nginx.enable {
          enable = true;
          port = lib.my.ports.prometheusNginx;
          scrapeUri = "http://127.0.0.1:${toString lib.my.ports.nginxStubStatus}/stub_status";
        };
      };
      # Allow prometheusExporter port in nebula's interface
      modules.services.nebula.firewall.inbound = [
        {
          port = lib.my.ports.prometheusExporter;
          proto = "tcp";
          group = "uptime";
        }
      ] ++ optional config.services.nginx.enable {
          port = lib.my.ports.nginxStubStatus;
          proto = "tcp";
          group = "uptime";
        };
    })

    # Enable Prometheus Server on hubs
    (mkIf (thisNode != null && thisNode.isHub) {
      services.prometheus = {
        enable = true;
        port = lib.my.ports.prometheusServer; # Server on 9090, Exporter on 9100
        globalConfig.scrape_interval = "15s";

        scrapeConfigs = [
          {
            job_name = "uptimewire-fleet";
            static_configs = mapAttrsToList (name: data: {
              targets = [ "${data.ip}:${toString lib.my.ports.prometheusExporter}" ];
              labels = {
                alias = name;
              };
            }) fleet;
          }
          {
            job_name = "uptimewire-fleet-nebula";
            static_configs = mapAttrsToList (name: data: {
              # Considering hostname.andrecadete.com contains nebula's IP addresses.
              targets = [ "${name}.andrecadete.com:${toString lib.my.ports.prometheusExporter}" ];
              labels = {
                alias = name;
              };
            }) fleet;
          }
          {
            job_name = "uptimewire-fleet-nginx";
            static_configs = mapAttrsToList (name: data: {
              targets = [ "${data.ip}:${toString lib.my.ports.prometheusNginx}" ];
              labels = {
                alias = name;
              };
            }) fleet;
          }
          {
            job_name = "uptimewire-fleet-nebula-nginx";
            static_configs = mapAttrsToList (name: data: {
              # Considering hostname.andrecadete.com contains nebula's IP addresses.
              targets = [ "${name}.andrecadete.com:${toString lib.my.ports.prometheusNginx}" ];
              labels = {
                alias = name;
              };
            }) fleet;
          }
          {
            job_name = "ctf-challs-https";
            metrics_path = "/probe";
            params = {
              module = [ "http_2xx" ];
            };
            static_configs = builtins.map (target: {
              targets = [ "${ctfchalls.prefix}${target}${ctfchalls.suffix}" ];
              labels.alias = target;
            }) ctfchalls.targets;
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = "127.0.0.1:${toString lib.my.ports.prometheusBlackbox}";
              }
            ];
          }
        ];
      };


    })
  ];
}
