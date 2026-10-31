# Targets to use in prometheus' blackbox
{
  lib,
  nixosConfigurations,
  ...
}:
let
  # modules.services.{nginx,traefik}.exposedServices on any host
  publicVhosts = lib.foldl' (
    acc: host:
    acc
    // lib.listToAttrs (
      map (entry: lib.nameValuePair entry.serverName entry) (
        lib.filter (entry: !entry.nebulaOnly) host.config.modules.services.nginx.exposedServices
        ++ host.config.modules.services.traefik.exposedServices
      )
    )
  ) { } (lib.attrValues nixosConfigurations);

  # modules.services.monitor.blackboxEndpoints on any host
  registeredEndpoints = lib.concatMap (host: host.config.modules.services.monitor.blackboxEndpoints) (
    lib.attrValues nixosConfigurations
  );

  mkStaticConfig = (config: builtins.map (target: {
      targets = [ "${config.prefix}${target}${config.suffix}" ];
      labels.alias = target;
    }) config.targets);
in
{
  blackbox = {
    hostEndpoints = lib.attrValues (
      lib.listToAttrs ( # avoid duplicates
        map (endpoint: lib.nameValuePair endpoint.url endpoint) (
          lib.mapAttrsToList (serverName: _: {
            alias = serverName;
            url = "https://${serverName}";
          }) publicVhosts
          ++ registeredEndpoints
        )
      )
    );

    # hosts publishing their traefik http_sd
    traefikHosts = lib.attrNames (
      lib.filterAttrs (
        _: host: with host.config.modules.services.traefik; enable && blackboxTargets.enable
      ) nixosConfigurations
    );

    ctfchalls = mkStaticConfig {
      targets = [
        "sqli1"
        "sqli2"
        "sqli3"
        "cmd1"
        "sxss1"
        "sxss2"
        "rxss1"
        "rxss2"
        "api1"
        "csrf1"
        "csrf1-hoster"
        "csrf2"
        "csrf3"
        "csrf3-hoster"
        "ssrf1"
        "ssrf1-hard"
        "ssrf2"
        "ssrf3"
        "domxss1"
        "pp1"
        "pp-lab"
        "pp2"
        "sspp1"
        "sspp2"
        "sspp3"
        "ssti1"
        "ssti2"
        "ssti3"
        "blog-sinfo2026"
        "bazingasim-sinfo2026"
      ];
      prefix = "https://";
      suffix = ".chall.ctf.andrecadete.com";
    };
  };
}
