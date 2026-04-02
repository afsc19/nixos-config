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
            isDefault = true;
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
                    },
                    {
                        "orgId": 1,
                        "name": "ctf_checks_15m",
                        "folder": "CTF",
                        "interval": "15m",
                        "rules": [
                            {
                              "uid": "ctf_checks_15m",
                              "title": "ctf_checks_15m",
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
                                          "expr": "probe_success{job=\"ctf-challs-https\"}",
                                          "instant": false,
                                          "intervalMs": 1000,
                                          "legendFormat": "__auto",
                                          "maxDataPoints": 43200,
                                          "range": true,
                                          "refId": "A"
                                      }
                                  },
                                  {
                                      "refId": "reducer",
                                      "queryType": "expression",
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
                                                          0,
                                                          0
                                                      ],
                                                      "type": "gt"
                                                  },
                                                  "operator": {
                                                      "type": "and"
                                                  },
                                                  "query": {
                                                      "params": []
                                                  },
                                                  "reducer": {
                                                      "params": [],
                                                      "type": "max"
                                                  },
                                                  "type": "query"
                                              }
                                          ],
                                          "datasource": {
                                              "name": "Expression",
                                              "type": "__expr__",
                                              "uid": "__expr__"
                                          },
                                          "expression": "A",
                                          "intervalMs": 1000,
                                          "maxDataPoints": 43200,
                                          "reducer": "max",
                                          "refId": "reducer",
                                          "type": "reduce"
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
                                                          0
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
                                          "expression": "reducer",
                                          "intervalMs": 1000,
                                          "maxDataPoints": 43200,
                                          "refId": "C",
                                          "type": "threshold"
                                      }
                                  }
                              ],
                              "noDataState": "NoData",
                              "execErrState": "Error",
                              "annotations": {
                                  "description": "One or more CTF Challenges aren't accessible via public https.",
                                  "summary": "CTF Challenges DOWN!"
                              },
                              "labels": {},
                              "isPaused": false,
                              "notification_settings": {
                                  "receiver": "discord"
                              }
                          }
                        ]
                    }
                ]
            }'';
        };
        dashboards.settings.providers = [
          {
            name = "Uptime Wire";
            folder = "Uptimewire";
            options.path = pkgs.writeTextDir "uptimewire-overview.json" (
              builtins.toJSON {
                uid = "uptimewire-overview";
                title = "Uptime Wire Overview";
                tags = [
                  "uptimewire"
                  "infrastructure"
                ];
                timezone = "browser";
                time = { from = "now-24h"; to = "now"; };
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
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
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
                  {
                    id = 2;
                    title = "Bandwidth Usage";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "sum by (alias) (max by (alias, device) (rate(node_network_receive_bytes_total{device!~\"lo|veth.*|docker.*|wg.*|nebula.*\"}[5m]))) * 8";
                        legendFormat = "{{alias}} - Download";
                        refId = "A";
                      }
                      {
                        expr = "sum by (alias) (max by (alias, device) (rate(node_network_transmit_bytes_total{device!~\"lo|veth.*|docker.*|wg.*|nebula.*\"}[5m]))) * 8";
                        legendFormat = "{{alias}} - Upload";
                        refId = "B";
                      }
                    ];
                    gridPos = {
                      h = 8;
                      w = 24;
                      x = 0;
                      y = 8;
                    };
                    fieldConfig = {
                      defaults = {
                        unit = "bps";
                        custom = {
                          drawStyle = "line";
                          lineInterpolation = "smooth";
                          lineWidth = 1;
                          fillOpacity = 10;
                          gradientMode = "opacity";
                        };
                      };
                    };
                  }
                ];
              }
            );
          }
          {
            name = "Uptime Wire Internals";
            folder = "Uptimewire";
            options.path = pkgs.writeTextDir "uptimewire-overview.json" (
              builtins.toJSON {
                uid = "uptimewire-internals";
                title = "Uptime Wire internals";
                tags = [
                  "uptimewire"
                  "infrastructure"
                ];
                timezone = "browser";
                time = { from = "now-24h"; to = "now"; };
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
                    title = "CPU Usage";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "100 - (avg by (alias)(irate(node_cpu_seconds_total{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", mode=\"idle\"}[30m])) * 100)";
                        legendFormat = "{{alias}}";
                        refId = "A";
                      }
                    ];
                    gridPos = {
                      h = 8;
                      w = 24;
                      x = 0;
                      y = 8;
                    };
                    fieldConfig = {
                      defaults = {
                        unit = "percent";
                        custom = {
                          drawStyle = "line";
                          lineInterpolation = "linear";
                          lineWidth = 1;
                          fillOpacity = 10;
                          gradientMode = "opacity";
                        };
                        min = 0;
                        max = 100;
                        thresholds = {
                          mode = "absolute";
                          steps = [
                            {
                              color = "green";
                              value = 0;
                            }
                            {
                              color = "red";
                              value = 80;
                            }
                          ];
                        };
                      };
                    };
                  }
                  {
                    id = 2;
                    title = "RAM Usage";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "max by alias (100 * (1 - (node_memory_MemAvailable_bytes{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\"}/node_memory_MemTotal_bytes{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\"})))";
                        legendFormat = "{{alias}}";
                        refId = "A";
                      }
                    ];
                    gridPos = {
                      h = 8;
                      w = 24;
                      x = 0;
                      y = 8;
                    };
                    fieldConfig = {
                      defaults = {
                        unit = "percent";
                        custom = {
                          drawStyle = "line";
                          lineInterpolation = "linear";
                          lineWidth = 1;
                          fillOpacity = 10;
                          gradientMode = "opacity";
                        };
                        min = 0;
                        max = 100;
                        thresholds = {
                          mode = "absolute";
                          steps = [
                            {
                              color = "green";
                              value = 0;
                            }
                            {
                              color = "red";
                              value = 80;
                            }
                          ];
                        };
                      };
                    };
                  }
                  {
                    id = 3;
                    title = "Disk Storage Usage";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "max by (alias) (100 * (
  1 - (
    node_filesystem_avail_bytes{
      job=~\"uptimewire-fleet|uptimewire-fleet-nebula\",
      fstype!~\"tmpfs|ramfs|overlay|squashfs\",
      mountpoint!~\"/run($|/)|/var/lib/docker($|/).*|/nix/store|/boot\"
    }
    /
    node_filesystem_size_bytes{
      job=~\"uptimewire-fleet|uptimewire-fleet-nebula\",
      fstype!~\"tmpfs|ramfs|overlay|squashfs\",
      mountpoint!~\"/run($|/)|/var/lib/docker($|/).*|/nix/store|/boot\"
}))";
                        legend = "{{alias}} - {{mountpoint}}";
                        refId = "A";
                      }
                    ];
                    gridPos = {
                      h = 8;
                      w = 24;
                      x = 0;
                      y = 8;
                    };
                    fieldConfig = {
                      defaults = {
                        unit = "percent";
                        custom = {
                          drawStyle = "line";
                          lineInterpolation = "linear";
                          lineWidth = 1;
                          fillOpacity = 10;
                          gradientMode = "opacity";
                        };
                        min = 0;
                        max = 100;
                        thresholds = {
                          mode = "absolute";
                          steps = [
                            {
                              color = "green";
                              value = 0;
                            }
                            {
                              color = "red";
                              value = 80;
                            }
                          ];
                        };
                      };
                    };
                  }
                                    {
                    id = 4;
                    title = "Disk Busy";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "max by (alias, device) (100 * rate(node_disk_io_time_seconds_total{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", device=~\"^(sd[a-z]+|vd[a-z]+|xvd[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+)$\"}[5m]))";
                        legendFormat = "{{alias}}";
                        refId = "A";
                      }
                    ];
                    gridPos = {
                      h = 8;
                      w = 24;
                      x = 0;
                      y = 8;
                    };
                    fieldConfig = {
                      defaults = {
                        unit = "percent";
                        custom = {
                          drawStyle = "line";
                          lineInterpolation = "linear";
                          lineWidth = 1;
                          fillOpacity = 10;
                          gradientMode = "opacity";
                        };
                        min = 0;
                        max = 100;
                        thresholds = {
                          mode = "absolute";
                          steps = [
                            {
                              color = "green";
                              value = 0;
                            }
                            {
                              color = "red";
                              value = 80;
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
            name = "Uptime Wire Family";
            folder = "Uptimewire Family";
            options.path = pkgs.writeTextDir "uptimewire-overview.json" (
              builtins.toJSON {
                uid = "uptimewire-overview-family";
                title = "Uptime Wire Overview Family";
                tags = [
                  "uptimewire"
                  "infrastructure"
                  "family"
                ];
                timezone = "browser";
                time = { from = "now-24h"; to = "now"; };
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
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "sum by (alias) (up{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\",alias=~\"favilla|calidor\"})";
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
                  {
                    id = 2;
                    title = "Bandwidth Usage";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "sum by (alias) (max by (alias, device) (rate(node_network_receive_bytes_total{device!~\"lo|veth*|docker*|wg.*|uptimeWire0|nebula.*\",alias=~\"favilla|calidor\"}[5m]))) * 8";
                        legendFormat = "{{alias}} - Download";
                        refId = "A";
                      }
                      {
                        expr = "sum by (alias) (max by (alias, device) (rate(node_network_transmit_bytes_total{device!~\"lo|veth*|docker*|wg.*|uptimeWire0|nebula.*\",alias=~\"favilla|calidor\"}[5m]))) * 8";
                        legendFormat = "{{alias}} - Upload";
                        refId = "B";
                      }
                    ];
                    gridPos = {
                      h = 8;
                      w = 24;
                      x = 0;
                      y = 8;
                    };
                    fieldConfig = {
                      defaults = {
                        unit = "bps";
                        custom = {
                          drawStyle = "line";
                          lineInterpolation = "smooth";
                          lineWidth = 1;
                          fillOpacity = 10;
                          gradientMode = "opacity";
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
            folder = "CTF";
            options.path = pkgs.writeTextDir "ctfchalls-overview.json" (
              builtins.toJSON {
                uid = "ctfchalls-overview";
                title = "CTF Challenges Overview";
                tags = [
                  "ctfchalls"
                  "infrastructure"
                ];
                timezone = "browser";
                time = { from = "now-6h"; to = "now"; };
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
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        # Ignore old targets using 'and ... @ end()'
                        expr = "last_over_time(probe_success{job=\"ctf-challs-https\"}[5m])";
                        instant = true;
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
