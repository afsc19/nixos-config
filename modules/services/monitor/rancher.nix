# A Rancher configuration
{
  config,
  lib,
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
    systemd.tmpfiles.rules = [
      "d /var/lib/rancher 0755 root root -"
    ];

    virtualisation.oci-containers.containers."rancher-server" = {
      image = "rancher/rancher:latest";
        pull = "always";
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
