# VMWare Workstation configuration.
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.virtualization.vmware;
in
{
  options.modules.virtualization.vmware.enable = mkEnableOption "vmware";

  config = mkIf cfg.enable {
    virtualisation.vmware.host.enable = true;
  };
}
