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
  options.modules.virtualization.docker = {
    enable = mkEnableOption "docker";
    useVirtualization = mkEnableOption "Use QEMU user virtualization to run x86_64 binaries";
  };

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
    
    systemd.services.docker-binfmt = mkIf (cfg.useVirtualization && pkgs.stdenv.hostPlatform.isAarch64) {
      description = "Register binfmt emulators for Docker";
      after = [ "network.target" "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.docker}/bin/docker run --privileged --rm tonistiigi/binfmt --install all";
        RemainAfterExit = true;
      };
    };

  };
}

