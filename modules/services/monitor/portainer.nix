# A Portainer configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modules.services.monitor.portainer;
  behindTraefik = config.modules.services.traefik.enable;
  hostName = config.networking.hostName;
in
{
  options.modules.services.monitor.portainer = {
    enable = mkEnableOption "Portainer container monitor";

    domain = mkOption {
      type = types.str;
      default =
        if hostName == lib.my.uptimewire.captain then
          "portainer.andrecadete.com"
        else
          "portainer.${hostName}.andrecadete.com";
      # im tryna doc it ok
      defaultText = lib.literalExpression ''
        if networking.hostName == lib.my.uptimewire.captain
        then "portainer.andrecadete.com"
        else "portainer.''${networking.hostName}.andrecadete.com"
      '';
      description = "Public hostname of Portainer, routed by traefik when it is enabled.";
    };
  };

  config = mkIf cfg.enable {
    modules.services.monitor.blackboxEndpoints = [
      {
        alias = "portainer-${hostName}";
        url = "https://${cfg.domain}";
      }
    ];

    # only reachable through traefik's labels below (no published port)
    assertions = [
      {
        assertion = config.modules.services.traefik.enable;
        message = "modules.services.monitor.portainer is only exposed through traefik: enable modules.services.traefik.";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/portainer 0755 root root -"
      "d /run/podman 0755 root root -"
    ];

    virtualisation.oci-containers.containers."portainer" = {
      image = "portainer/portainer-ce:latest";
      pull = "always";
      # ports = [ "51000:9000" ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/var/lib/portainer:/data"
        "/run/podman/podman.sock:/run/podman/podman.sock"
      ];
      labels = mkIf behindTraefik {
        "traefik.enable" = "true";
        "traefik.http.routers.portainer.rule" = "Host(`${cfg.domain}`)";
        "traefik.http.services.portainer.loadbalancer.server.port" = "9000";
      };
    };
  };
}
