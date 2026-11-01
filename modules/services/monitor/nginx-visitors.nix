# Unique nginx visitors
# keyed with (ip, user-agent)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    filterAttrs
    mapAttrsToList
    mkAfter
    mkIf
    mkMerge
    ;
  inherit (lib.my.uptimewire) fleet;
  thisNode = fleet."${config.networking.hostName}" or null;

  # blackbox probes leave from the hubs' public addresses (world.<hub>.andrecadete.com)
  blackboxHosts = map (hub: hub.endpoint) (
    attrValues (filterAttrs (_: data: data.isHub && data ? endpoint) fleet)
  );
in
{
  config = mkIf (thisNode != null && config.modules.services.nginx.enable) (mkMerge [
    {
      services.nginx.commonHttpConfig = mkAfter ''
        log_format visitors escape=json '{"vhost":"$server_name","ip":"$remote_addr","ua":"$http_user_agent"}';
        access_log syslog:server=127.0.0.1:${toString lib.my.ports.nginxVisitorsSyslog},tag=visitors,nohostname visitors;
      '';

      systemd.services.nginx-visitors-exporter = {
        description = "Prometheus exporter for unique nginx visitors";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          ExecStart = lib.escapeShellArgs (
            [
              "${pkgs.python3}/bin/python3"
              "${./nginx-visitors.py}"
              "--syslog-port"
              (toString lib.my.ports.nginxVisitorsSyslog)
              "--metrics-port"
              (toString lib.my.ports.prometheusNginxVisitors)
              "--state-file"
              "/var/lib/nginx-visitors-exporter/visits.json"
            ]
            ++ lib.concatMap (host: [
              "--blackbox-host"
              host
            ]) blackboxHosts
          );
          Restart = "always";
          DynamicUser = true;
          StateDirectory = "nginx-visitors-exporter";
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };

      networking.firewall.interfaces.uptimeWire0.allowedTCPPorts = [
        lib.my.ports.prometheusNginxVisitors
      ];
      modules.services.nebula.firewall.inbound = [
        {
          port = lib.my.ports.prometheusNginxVisitors;
          proto = "tcp";
          group = "uptime";
        }
      ];
    }

    (mkIf thisNode.isHub {
      services.prometheus.scrapeConfigs = [
        {
          job_name = "uptimewire-fleet-nginx-visitors";
          static_configs = mapAttrsToList (name: data: {
            targets = [ "${data.ip}:${toString lib.my.ports.prometheusNginxVisitors}" ];
            labels = {
              alias = name;
            };
          }) fleet;
        }
        {
          job_name = "uptimewire-fleet-nebula-nginx-visitors";
          static_configs = mapAttrsToList (name: _data: {
            targets = [ "${name}.andrecadete.com:${toString lib.my.ports.prometheusNginxVisitors}" ];
            labels = {
              alias = name;
            };
          }) fleet;
        }
      ];
    })
  ]);
}
