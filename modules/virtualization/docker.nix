# Docker configuration.
{
  config,
  lib,
  user,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.virtualization.docker;
in
{
  options.modules.virtualization.docker.enable = mkEnableOption "docker";

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
    users.users.${user}.extraGroups = [ "docker" ];

    environment.systemPackages = with pkgs; [
      docker-buildx
    ];
  };
}
