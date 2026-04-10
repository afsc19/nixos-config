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
                templating = {
                  list = [
                    {
                      name = "alias";
                      type = "query";
                      datasource = {
                        type = "prometheus";
                        uid = "prometheus";
                      };
                      query = "label_values(up{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\"}, alias)";
                      refresh = 1;
                      multi = true;
                      includeAll = true;
                    }
                  ];
                };
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
                    title = "$alias Bandwidth Usage";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    repeat = "alias";
                    repeatDirection = "h";
                    maxPerRow = 4;
                    targets = [
                      {
                        expr = "(sum(max by (device) (rate(node_network_receive_bytes_total{alias=~\"^$alias$\", device!~\"lo|veth.*|docker.*|wg.*|nebula.*|uptimeWire0\"}[30s]))) or max by (alias) (rate(windows_net_bytes_received_total{alias=~\"^$alias$\"}[30s]))) * 8";
                        legendFormat = "Download";
                        refId = "A";
                      }
                      {
                        expr = "(sum(max by (device) (rate(node_network_transmit_bytes_total{alias=~\"^$alias$\", device!~\"lo|veth.*|docker.*|wg.*|nebula.*|uptimeWire0\"}[30s]))) or max by (alias) (rate(windows_net_bytes_sent_total{alias=~\"^$alias$\"}[30s]))) * 8";
                        legendFormat = "Upload";
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
                templating = {
                  list = [
                    {
                      name = "alias";
                      type = "query";
                      datasource = {
                        type = "prometheus";
                        uid = "prometheus";
                      };
                      query = "label_values(up{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\"}, alias)";
                      refresh = 1;
                      multi = true;
                      includeAll = true;
                    }
                  ];
                };
                panels = [
                  {
                    id = 1;
                    title = "$alias CPU Usage";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    repeat = "alias";
                    repeatDirection = "h";
                    maxPerRow = 4;
                    targets = [
                      {
                        expr = "100 - max by (alias) (avg by (alias, job)(irate(node_cpu_seconds_total{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", mode=\"idle\", alias=~\"^$alias$\"}[30s]) or irate(windows_cpu_time_total{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", mode=\"idle\", alias=~\"^$alias$\"}[30s])) * 100)";
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
                    title = "$alias RAM Usage";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    repeat = "alias";
                    repeatDirection = "h";
                    maxPerRow = 4;
                    targets = [
                      {
                        expr = "max by (alias) (100 * (1 - ((node_memory_MemAvailable_bytes{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", alias=~\"^$alias$\"} or windows_memory_available_bytes{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", alias=~\"^$alias$\"})/(node_memory_MemTotal_bytes{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", alias=~\"^$alias$\"} or windows_memory_physical_total_bytes{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", alias=~\"^$alias$\"}))))";
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
                    title = "$alias Disk Storage Usage";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    repeat = "alias";
                    repeatDirection = "h";
                    maxPerRow = 4;
                    targets = [
                      {
                        expr = "max by (alias, mountpoint, volume) (100 * (
  1 - (
    (node_filesystem_avail_bytes{
      job=~\"uptimewire-fleet|uptimewire-fleet-nebula\",
      fstype!~\"tmpfs|ramfs|overlay|squashfs\",
      mountpoint!~\"/run($|/)|/var/lib/docker($|/).*|/nix/store|/boot\",
      alias=~\"^$alias$\"
    }
    or
    windows_logical_disk_free_bytes{
      job=~\"uptimewire-fleet|uptimewire-fleet-nebula\",
      volume!~\"HarddiskVolume.*\",
      alias=~\"^$alias$\"
    })
    /
    (node_filesystem_size_bytes{
      job=~\"uptimewire-fleet|uptimewire-fleet-nebula\",
      fstype!~\"tmpfs|ramfs|overlay|squashfs\",
      mountpoint!~\"/run($|/)|/var/lib/docker($|/).*|/nix/store|/boot\",
      alias=~\"^$alias$\"
    }
    or 
    windows_logical_disk_size_bytes{
      job=~\"uptimewire-fleet|uptimewire-fleet-nebula\",
      volume!~\"HarddiskVolume.*\",
      alias=~\"^$alias$\"
    })
  )))";
                        legendFormat = "{{mountpoint}}{{volume}}";
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
                    title = "$alias Disk Busy";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    repeat = "alias";
                    repeatDirection = "h";
                    maxPerRow = 4;
                    targets = [
                      {
                        expr = "max by (alias, device, volume) (100 * (
  rate(node_disk_io_time_seconds_total{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", alias=~\"^$alias$\", device=~\"^(sd[a-z]+|vd[a-z]+|xvd[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+)$\"}[30s])
  or
  (
    (rate(windows_logical_disk_read_seconds_total{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", alias=~\"^$alias$\", volume!~\"HarddiskVolume.*\"}[30s])
    +
    rate(windows_logical_disk_write_seconds_total{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", alias=~\"^$alias$\", volume!~\"HarddiskVolume.*\"}[30s])
    )
  /
    (rate(windows_logical_disk_read_seconds_total{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", alias=~\"^$alias$\", volume!~\"HarddiskVolume.*\"}[30s])
    +
    rate(windows_logical_disk_write_seconds_total{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", alias=~\"^$alias$\", volume!~\"HarddiskVolume.*\"}[30s])
    +
    rate(windows_logical_disk_idle_seconds_total{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", alias=~\"^$alias$\", volume!~\"HarddiskVolume.*\"}[30s])
    )
  )
))";
                        legendFormat = "{{device}}{{volume}}";
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
                templating = {
                  list = [
                    {
                      name = "alias";
                      type = "query";
                      datasource = {
                        type = "prometheus";
                        uid = "prometheus";
                      };
                      query = "label_values(up{job=~\"uptimewire-fleet|uptimewire-fleet-nebula\", alias=~\"favilla|calidor\"}, alias)";
                      refresh = 1;
                      multi = true;
                      includeAll = true;
                    }
                  ];
                };
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
                    title = "$alias Bandwidth Usage";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    repeat = "alias";
                    repeatDirection = "h";
                    maxPerRow = 4;
                    targets = [
                      {
                        expr = "(sum(max by (device) (rate(node_network_receive_bytes_total{alias=~\"^$alias$\", device!~\"lo|veth.*|docker.*|wg.*|nebula.*|uptimeWire0\"}[30s]))) or max by (alias) (rate(windows_net_bytes_received_total{alias=~\"^$alias$\"}[30s]))) * 8";
                        legendFormat = "Download";
                        refId = "A";
                      }
                      {
                        expr = "(sum(max by (device) (rate(node_network_transmit_bytes_total{alias=~\"^$alias$\", device!~\"lo|veth.*|docker.*|wg.*|nebula.*|uptimeWire0\"}[30s]))) or max by (alias) (rate(windows_net_bytes_sent_total{alias=~\"^$alias$\"}[30s]))) * 8";
                        legendFormat = "Upload";
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
                        expr = "last_over_time(probe_success{job=\"ctf-challs-https\"}[30s])";
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
          # NGINX
          {
            name = "NGINX";
            folder = "NGINX";
            options.path = pkgs.writeTextDir "nginx-overview.json" (
              builtins.toJSON {
                uid = "nginx-overview";
                title = "NGINX Overview";
                tags = [
                  "nginx"
                  "uptimewire"
                  "infrastructure"
                ];
                timezone = "browser";
                schemaVersion = 30;
                version = 1;
                editable = true;
                graphTooltip = 1;
                time = { from = "now-24h"; to = "now"; };
                refresh =
                  if config.services.prometheus.enable then
                    config.services.prometheus.globalConfig.scrape_interval
                  else
                    "15s";

                templating = {
                  list = [
                    {
                      name = "instance";
                      type = "query";
                      datasource = {
                        type = "prometheus";
                        uid = "prometheus";
                      };
                      definition = "label_values(nginx_up{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\"}, instance)";
                      query = {
                        query = "label_values(nginx_up{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\"}, instance)";
                        refId = "Prometheus-instance-Variable-Query";
                      };
                      refresh = 1;
                      includeAll = true;
                      multi = true;
                      current = {
                        selected = true;
                        text = [ "All" ];
                        value = [ "$__all" ];
                      };
                    }
                  ];
                };

                panels = [
                  {
                    id = 1;
                    title = "NGINX Up";
                    type = "stat";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "max by (alias)(nginx_up{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\"})";
                        refId = "A";
                      }
                    ];
                    gridPos = { h = 4; w = 6; x = 0; y = 0; };
                    options = {
                      reduceOptions = {
                        values = false;
                        calcs = [ "lastNotNull" ];
                        fields = "";
                      };
                      orientation = "auto";
                      textMode = "value";
                      colorMode = "background";
                      graphMode = "none";
                      wideLayout = true;
                    };
                    fieldConfig.defaults = {
                      mappings = [
                        {
                          type = "special";
                          options = {
                            match = "null";
                            result = {
                              text = "NO DATA";
                              color = "gray";
                            };
                          };
                        }
                      ];
                      color.mode = "thresholds";
                      thresholds = {
                        mode = "absolute";
                        steps = [
                          { color = "red"; value = null; }
                          { color = "green"; value = 1; }
                        ];
                      };
                    };
                  }

                  {
                    id = 2;
                    title = "Request Rate";
                    type = "stat";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "max by (alias) (rate(nginx_http_requests_total{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"}[30s]))";
                        refId = "A";
                      }
                    ];
                    gridPos = { h = 4; w = 6; x = 6; y = 0; };
                    options = {
                      reduceOptions = {
                        values = false;
                        calcs = [ "lastNotNull" ];
                        fields = "";
                      };
                      orientation = "auto";
                      textMode = "value";
                      colorMode = "background";
                      graphMode = "area";
                      wideLayout = true;
                    };
                    fieldConfig.defaults = {
                      unit = "reqps";
                      decimals = 2;
                      color.mode = "thresholds";
                      thresholds = {
                        mode = "absolute";
                        steps = [
                          { color = "green"; value = null; }
                          { color = "orange"; value = 100; }
                          { color = "red"; value = 500; }
                        ];
                      };
                    };
                  }

                  {
                    id = 3;
                    title = "Active Connections";
                    type = "stat";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "max by (alias) (nginx_connections_active{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"})";
                        refId = "A";
                      }
                    ];
                    gridPos = { h = 4; w = 6; x = 12; y = 0; };
                    options = {
                      reduceOptions = {
                        values = false;
                        calcs = [ "lastNotNull" ];
                        fields = "";
                      };
                      orientation = "auto";
                      textMode = "value";
                      colorMode = "background";
                      graphMode = "area";
                      wideLayout = true;
                    };
                    fieldConfig.defaults = {
                      unit = "short";
                      decimals = 0;
                      color.mode = "thresholds";
                      thresholds = {
                        mode = "absolute";
                        steps = [
                          { color = "green"; value = null; }
                          { color = "orange"; value = 100; }
                          { color = "red"; value = 500; }
                        ];
                      };
                    };
                  }

                  {
                    id = 4;
                    title = "Handled / Accepted";
                    type = "stat";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "max by (alias) (sum(rate(nginx_connections_handled{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"}[30s])) / clamp_min(sum(rate(nginx_connections_accepted{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"}[30s])), 0.0001))";
                        refId = "A";
                      }
                    ];
                    gridPos = { h = 4; w = 6; x = 18; y = 0; };
                    options = {
                      reduceOptions = {
                        values = false;
                        calcs = [ "lastNotNull" ];
                        fields = "";
                      };
                      orientation = "auto";
                      textMode = "value";
                      colorMode = "background";
                      graphMode = "none";
                      wideLayout = true;
                    };
                    fieldConfig.defaults = {
                      unit = "percentunit";
                      decimals = 3;
                      min = 0;
                      max = 1;
                      color.mode = "thresholds";
                      thresholds = {
                        mode = "absolute";
                        steps = [
                          { color = "red"; value = null; }
                          { color = "orange"; value = 0.95; }
                          { color = "green"; value = 0.999; }
                        ];
                      };
                    };
                  }

                  {
                    id = 5;
                    title = "Requests Over Time";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "max by (alias) (sum by (instance) (rate(nginx_http_requests_total{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"}[30s])))";
                        legendFormat = "{{alias}}";
                        refId = "A";
                      }
                    ];
                    gridPos = { h = 8; w = 12; x = 0; y = 4; };
                    options = {
                      legend = {
                        displayMode = "list";
                        placement = "bottom";
                        showLegend = true;
                      };
                      tooltip = {
                        mode = "multi";
                        sort = "desc";
                      };
                    };
                    fieldConfig.defaults = {
                      unit = "reqps";
                      color.mode = "palette-classic";
                      custom = {
                        drawStyle = "line";
                        lineInterpolation = "smooth";
                        lineWidth = 2;
                        fillOpacity = 10;
                        gradientMode = "opacity";
                        showPoints = "never";
                      };
                    };
                  }

                  {
                    id = 6;
                    title = "Connection States";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "max by (alias) (sum by (instance) (nginx_connections_active{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"}))";
                        legendFormat = "{{instance}} active";
                        refId = "A";
                      }
                      {
                        expr = "max by (alias) (sum by (instance) (nginx_connections_reading{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"}))";
                        legendFormat = "{{instance}} reading";
                        refId = "B";
                      }
                      {
                        expr = "max by (alias) (sum by (instance) (nginx_connections_writing{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"}))";
                        legendFormat = "{{instance}} writing";
                        refId = "C";
                      }
                      {
                        expr = "max by (alias) (sum by (instance) (nginx_connections_waiting{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"}))";
                        legendFormat = "{{instance}} waiting";
                        refId = "D";
                      }
                    ];
                    gridPos = { h = 8; w = 12; x = 12; y = 4; };
                    options = {
                      legend = {
                        displayMode = "list";
                        placement = "bottom";
                        showLegend = true;
                      };
                      tooltip = {
                        mode = "multi";
                        sort = "desc";
                      };
                    };
                    fieldConfig.defaults = {
                      unit = "short";
                      color.mode = "palette-classic";
                      custom = {
                        drawStyle = "line";
                        lineInterpolation = "smooth";
                        lineWidth = 2;
                        fillOpacity = 8;
                        gradientMode = "opacity";
                        showPoints = "never";
                      };
                    };
                  }

                  {
                    id = 7;
                    title = "Accepted vs Handled";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "max by (alias) (sum by (instance) (rate(nginx_connections_accepted{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"}[30s])))";
                        legendFormat = "{{instance}} accepted/s";
                        refId = "A";
                      }
                      {
                        expr = "max by (alias) (sum by (instance) (rate(nginx_connections_handled{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"}[30s])))";
                        legendFormat = "{{instance}} handled/s";
                        refId = "B";
                      }
                    ];
                    gridPos = { h = 8; w = 12; x = 0; y = 12; };
                    options = {
                      legend = {
                        displayMode = "list";
                        placement = "bottom";
                        showLegend = true;
                      };
                      tooltip = {
                        mode = "multi";
                        sort = "desc";
                      };
                    };
                    fieldConfig.defaults = {
                      unit = "cps";
                      color.mode = "palette-classic";
                      custom = {
                        drawStyle = "line";
                        lineInterpolation = "smooth";
                        lineWidth = 2;
                        fillOpacity = 8;
                        gradientMode = "opacity";
                        showPoints = "never";
                      };
                    };
                  }

                  {
                    id = 8;
                    title = "Total Requests";
                    type = "timeseries";
                    datasource = {
                      type = "prometheus";
                      uid = "prometheus";
                    };
                    targets = [
                      {
                        expr = "max by (alias) (sum by (instance) (nginx_http_requests_total{job=~\"uptimewire-fleet-nginx|uptimewire-fleet-nebula-nginx\",instance=~\"$instance\"}))";
                        legendFormat = "{{instance}}";
                        refId = "A";
                      }
                    ];
                    gridPos = { h = 8; w = 12; x = 12; y = 12; };
                    options = {
                      legend = {
                        displayMode = "list";
                        placement = "bottom";
                        showLegend = true;
                      };
                      tooltip = {
                        mode = "multi";
                        sort = "desc";
                      };
                    };
                    fieldConfig.defaults = {
                      unit = "short";
                      color.mode = "palette-classic";
                      custom = {
                        drawStyle = "line";
                        lineInterpolation = "smooth";
                        lineWidth = 2;
                        fillOpacity = 8;
                        gradientMode = "opacity";
                        showPoints = "never";
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
