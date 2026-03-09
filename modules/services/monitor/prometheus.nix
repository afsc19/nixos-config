# Prometheus configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    my
    mapAttrsToList
    ;
  inherit (lib.my.uptimewire) fleet;
  thisNode = fleet."${config.networking.hostName}" or null;
in
{
  config = mkMerge [
    # Enable Node Exporter on all fleet members
    (mkIf (thisNode != null) {
      services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = lib.my.ports.prometheusExporter;
      };
      # Allow prometheusExporter port in nebula's interface
      modules.services.nebula.firewall.inbound = [
        {
          port = lib.my.ports.prometheusExporter;
          proto = "tcp";
          group = "uptime";
        }
      ];
    })

    # 2. Enable Prometheus Server on hubs
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
        ];
      };


    })
  ];
}
