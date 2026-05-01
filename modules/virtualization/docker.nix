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

  # Lightweight static qemu-user
  qemu-user-static = pkgs.qemu-user.overrideAttrs (oldAttrs: {
    configureFlags = (oldAttrs.configureFlags or []) ++ [
      "--static"
      "--disable-gnutls"
      "--disable-nettle"
      "--disable-gcrypt"
    ];
  });
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
    
    boot.binfmt = mkIf (cfg.useVirtualization && pkgs.stdenv.hostPlatform.isAarch64) {
      # Run other arch binaries using QEMU
      emulatedSystems = [ "x86_64-linux" ];

      registrations = {
        # General pwn challenges
        x86_64-linux = {
          interpreter = "${qemu-user-static}/bin/qemu-x86_64";
          fixBinary = true;
          wrapInterpreterInShell = false;
          magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
          mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
        };
      };
    };

  };
}
