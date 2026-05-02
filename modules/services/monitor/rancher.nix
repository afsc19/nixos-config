
# A Rancher configuration
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

  cfg = config.modules.services.monitor.rancher;
in
{
  options.modules.services.monitor.rancher.enable = mkEnableOption "Rancher cluster monitor";

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."rancher-server" = {
      image = "rancher/rancher:latest";
      ports = [
        "127.0.0.1:51001:80"
        # "80:80"
        # "443:443"
      ];
      volumes = [
        "/var/lib/rancher:/var/lib/rancher"
      ];
      extraOptions = [
        "--privileged"
      ];
    };
  };
}


