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

          domain = "grafana.andrecadete.com";
          root_url = "https://grafana.andrecadete.com/";
        };
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            uid = "prometheus";
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString lib.my.ports.prometheusServer}";
          }
        ];

        alerting = {
          contactPoints.settings.contactPoints = [
            {
              orgId = 1;
              name = "discord";
              receivers = [
                {
                  uid = "discord";
                  type = "discord";
                  settings = {
                    url = "$__file{${config.age.secrets.grafanaDiscordWebhook.path}}";
                    use_discord_username = true;
                  };
                  disableResolveMessage = false;
                }
              ];
            }
          ];
          # policies.settings.policies = [
          #   {
          #     receiver = "Discord-Uptimewire";
          #     group_by = [ "grafana_folder" "alertname" ];
          #     routes = [
          #       {
          #         receiver = "Discord-Uptimewire";
          #         matchers = [ "alertname = CalidorOnline" ];
          #         continue = true;
          #       }
          #     ];
          #   }
          # ];
          rules.settings = builtins.fromJSON ''
            {
                "apiVersion": 1,
                "groups": [
                    {
                        "orgId": 1,
                        "name": "up_checks_1h",
                        "folder": "Uptimewire",
                        "interval": "1h",
                        "rules": [
                            {
                                "uid": "calidor-up",
                                "title": "calidor-up",
                                "condition": "C",
                                "data": [
                                    {
                                        "refId": "A",
                                        "relativeTimeRange": {
                                            "from": 600,
                                            "to": 0
                                        },
                                        "datasourceUid": "prometheus",
                                        "model": {
                                            "editorMode": "builder",
                                            "expr": "up{alias=\"calidor\"}",
                                            "instant": true,
                                            "intervalMs": 1000,
                                            "legendFormat": "__auto",
                                            "maxDataPoints": 43200,
                                            "range": false,
                                            "refId": "A"
                                        }
                                    },
                                    {
                                        "refId": "C",
                                        "relativeTimeRange": {
                                            "from": 0,
                                            "to": 0
                                        },
                                        "datasourceUid": "__expr__",
                                        "model": {
                                            "conditions": [
                                                {
                                                    "evaluator": {
                                                        "params": [
                                                            1
                                                        ],
                                                        "type": "eq"
                                                    },
                                                    "operator": {
                                                        "type": "and"
                                                    },
                                                    "query": {
                                                        "params": [
                                                            "C"
                                                        ]
                                                    },
                                                    "reducer": {
                                                        "params": [],
                                                        "type": "last"
                                                    },
                                                    "type": "query"
                                                }
                                            ],
                                            "datasource": {
                                                "type": "__expr__",
                                                "uid": "__expr__"
                                            },
                                            "expression": "A",
                                            "intervalMs": 1000,
                                            "maxDataPoints": 43200,
                                            "refId": "C",
                                            "type": "threshold"
                                        }
                                    }
                                ],
                                "noDataState": "NoData",
                                "execErrState": "Error",
                                "for": "1h",
                                "annotations": {
                                    "description": "Calidor has been detected to be UP",
                                    "summary": "Calidor is UP!"
                                },
                                "isPaused": false,
                                "notification_settings": {
                                    "receiver": "discord"
                                }
                            }
                        ]
                    }
                ]
            }'';
          # rules.settings.groups = [
          #   {
          #     name = "up_checks_1h";
          #     folder = "Uptimewire";
          #     interval = "1h";
          #     rules = [
          #       {
          #         uid = "calidor-up";
          #         title = "calidor-up";
          #         condition = "C";
          #         data = [
          #           {
          #             refId = "A";
          #             relativeTimeRange = { from = 600; to = 0; };
          #             datasourceUid = "prometheus";
          #             model = {
          #               editorMode = "builder";
          #               expr = "up{alias=\"calidor\"}";
          #               instant = true;
          #               intervalMs = 1000;
          #               maxDataPoints = 43200;
          #               range = false;
          #               refId = "A";
          #             };
          #           }
          #         ];
          #         noDataState = "NoData";
          #         execErrState = "Error";
          #         for = "1h";
          #         annotations = {
          #           summary = "Calidor is UP!";
          #           description = "Calidor instance is reachable via Uptimewire.";
          #         };
          #         isPaused = false;
          #         notification_settings = {
          #           receiver = "discord";
          #         };
          #         labels = {
          #           severity = "info";
          #         };
          #       }
          #     ];
          #   }
          # ];
        };
        dashboards.settings.providers = [
          {
            name = "Uptime Wire";
            options.path = pkgs.writeTextDir "uptimewire-overview.json" (
              builtins.toJSON {
                uid = "uptimewire-overview";
                title = "Uptime Wire Overview";
                tags = [
                  "uptimewire"
                  "infrastructure"
                ];
                timezone = "browser";
                refresh =
                  if config.services.prometheus.enable then
                    config.services.prometheus.globalConfig.scrape_interval
                  else
                    "15s"
                  ;
                schemaVersion = 30;
                panels = [
                  {
                    id = 1;
                    title = "Fleet Status";
                    type = "stat";
                    datasource = "Prometheus";
                    targets = [
                      {
                        expr = "sum by (alias) (up{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\"})";
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
                              "0" = {
                                color = "red";
                                text = "DOWN";
                                index = 0;
                              };
                              "1" = {
                                color = "orange";
                                text = "MUMBLE";
                                index = 1;
                              };
                              "2" = {
                                color = "green";
                                text = "UP";
                                index = 2;
                              };
                            };
                          }
                        ];
                        color = {
                          mode = "thresholds";
                        };
                        thresholds = {
                          mode = "absolute";
                          steps = [
                            {
                              color = "red";
                              value = null;
                            }
                            {
                              color = "orange";
                              value = 1;
                            }
                            {
                              color = "green";
                              value = 2;
                            }
                          ];
                        };
                      };
                    };
                  }
                ];
              }
            );
          }
          {
            name = "CTF Challenges";
            options.path = pkgs.writeTextDir "ctfchalls-overview.json" (
              builtins.toJSON {
                uid = "ctfchalls-overview";
                title = "CTF Challenges Overview";
                tags = [
                  "ctfchalls"
                  "infrastructure"
                ];
                timezone = "browser";
                refresh =
                  if config.services.prometheus.enable then
                    config.services.prometheus.globalConfig.scrape_interval
                  else
                    "15s"
                  ;
                schemaVersion = 30;
                panels = [
                  {
                    id = 1;
                    title = "CTF Challenges Status";
                    type = "gauge";
                    datasource = "Prometheus";
                    targets = [
                      {
                        # Ignore old targets using 'and ... @ end()'
                        expr = "probe_success{job=\"ctf-challs-https\"}"; 
                        legendFormat = "{{alias}}";
                        refId = "A";
                      }
                    ];
                    gridPos = {
                      h = 24;
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
                              "0" = {
                                color = "red";
                                text = "DOWN";
                                index = 0;
                              };
                              "1" = {
                                color = "green";
                                text = "UP";
                                index = 1;
                              };
                            };
                          }
                        ];
                        color = {
                          mode = "thresholds";
                        };
                        min = 0;
                        max = 1;
                        thresholds = {
                          mode = "absolute";
                          steps = [
                            {
                              color = "red";
                              value = null;
                            }
                            {
                              color = "green";
                              value = 1;
                            }
                          ];
                        };
                      };
                    };
                  }
                ];
              }
            );
          }
        ];
      };
    };
  };
}
