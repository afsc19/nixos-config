# Grafana configuration
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.my.uptimewire) fleet;
  thisNode = fleet."${config.networking.hostName}" or null;
in
{
  # Automatically enable grafana if it's a hub.
  config = mkIf (thisNode != null && thisNode.isHub) {
    age.secrets.grafanaDiscordWebhook = {
      file = secrets.sylva.grafanaDiscordWebhook;
      owner = "grafana";
    };

    networking.firewall.allowedTCPPorts = [ lib.my.ports.grafana ];

    services.grafana = {
      enable = true;
      
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = lib.my.ports.grafana;
        };
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString lib.my.ports.prometheusServer}";
            isDefault = true;
          }
        ];
        
        alerting = {
          contactPoints.settings.contactPoints = [
            {
              name = "Discord-Uptimewire";
              type = "discord";
              settings = {
                url = "$__file{${config.age.secrets.grafanaDiscordWebhook.path}}";
              };
            }
          ];
          policies.settings.policies = [
            {
              receiver = "Discord-Uptimewire";
              routes = [
                {
                  receiver = "Discord-Uptimewire";
                  object_matches = [ [ "alertname" "=" "CalidorOnline" ] ];
                  continue = true;
                }
              ];
              # Match alerts with label alertname="CalidorOnline"
              matchers = [ "alertname = CalidorOnline" ];
            }
          ];
          rules.settings.groups = [
            {
              name = "Uptimewire-Alerts";
              folder = "Uptimewire";
              interval = "1m";
              rules = [
                {
                  uid = "calidor-online";
                  title = "CalidorOnline";
                  condition = "A";
                  data = [
                    {
                      refId = "A";
                      relativeTimeRange = { from = 600; to = 0; };
                      datasourceUid = "Prometheus"; # Automatically resolves to the UID of the datasource named "Prometheus"
                      model = {
                        expr = "up{alias=\"calidor\"} == 1";
                        intervalMs = 1000;
                        maxDataPoints = 43200;
                        refId = "A";
                      };
                    }
                  ];
                  # Fire immediately effectively
                  for = "30s"; 
                  annotations = {
                    summary = "Calidor is ONLINE";
                    description = "Calidor instance is reachable via Uptimewire.";
                  };
                  labels = {
                    severity = "info";
                  };
                }
              ];
            }
          ];
        };
        dashboards.settings.providers = [
          {
            name = "Uptime Wire";
            options.path = pkgs.writeTextDir "uptimewire-overview.json" (builtins.toJSON {
              uid = "uptimewire-overview";
              title = "Uptime Wire Overview";
              tags = [ "uptimewire" "infrastructure" ];
              timezone = "browser";
              schemaVersion = 30;
              panels = [
                {
                  id = 1;
                  title = "Fleet Status";
                  type = "gauge";
                  datasource = "Prometheus";
                  targets = [
                    {
                      expr = "up{job=\"uptimewire-fleet\"}";
                      legendFormat = "{{alias}}";
                      refId = "A";
                    }
                  ];
                  gridPos = {
                    h = 8;
                    w = 24;
                    x = 0;
                    y = 0;
                  };
                  fieldConfig = {
                    defaults = {
                      mappings = [
                        {
                          type = "value";
                          options = {
                            "0" = { color = "red"; text = "DOWN"; index = 0; };
                            "1" = { color = "green"; text = "UP"; index = 1; };
                          };
                        }
                      ];
                      color = { mode = "thresholds"; };
                      thresholds = {
                        mode = "absolute";
                        steps = [
                          { color = "red"; value = null; }
                          { color = "green"; value = 1; }
                        ];
                      };
                    };
                  };
                }
              ];
            });
          }
        ];
      };
    };
  };
}
