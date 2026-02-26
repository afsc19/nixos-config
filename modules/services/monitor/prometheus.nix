# Prometheus configuration
{
  config,
  lib,
  secrets,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    my
    mapAttrsToList
    filterAttrs
    mkForce
    optional
    ;
  inherit (lib.my.uptimewire) fleet port;
  thisNode = fleet."${config.networking.hostName}" or null;
in
{
  # Automatically enable prometheus if it's a hub.
  config = mkIf (thisNode != null && thisNode.isHub) {
    services.prometheus = {
      enable = true;
      port = my.ports.prometheus;
      globalConfig.scrape_interval = "1m";

      scrapeConfigs = [
        {
          job_name = "uptimewire-fleet";
          static_configs = mapAttrsToList (name: data: {
            targets = [ "${data.ip}:${toString my.ports.prometheus}" ];
            labels = {
              alias = name;
            };
          }) fleet;
        }
      ];
    };
  };
}
