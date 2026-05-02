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

    nixpkgs.overlays = [
      (final: prev: {
        qemu-user = prev.qemu-user.overrideAttrs (old: {
          configureFlags = (old.configureFlags or []) ++ [
            "--disable-pie"
          ];
        });
      })
    ];

    
    boot.binfmt = mkIf (cfg.useVirtualization && pkgs.stdenv.hostPlatform.isAarch64) {
      emulatedSystems = [ "x86_64-linux" ];
      preferStaticEmulators = true; # Make it work with Docker
    };

  };
}

