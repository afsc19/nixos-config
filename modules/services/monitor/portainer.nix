
# A Portainer configuration
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
    mkIf
    ;

  cfg = config.modules.services.monitor.portainer;
in
{
  options.modules.services.monitor.portainer.enable = mkEnableOption "Portainer container monitor";

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /var/lib/portainer 0755 root root -"
    ];

    virtualisation.oci-containers.containers."portainer" = {
      image = "portainer/portainer-ce:latest";
      ports = [ "51000:9000" ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/var/lib/portainer:/data"
      ];
    };
  };
}


