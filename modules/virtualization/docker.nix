# Docker configuration.
{
  config,
  lib,
  user,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.virtualization.docker;
in
{
  options.modules.virtualization.docker.enable = mkEnableOption "docker";

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;
    users.users.${user}.extraGroups = [ "docker" ];
  };
}
