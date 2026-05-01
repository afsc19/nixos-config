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

  qemu-x86_64-static = pkgs.stdenv.mkDerivation {
    name = "qemu-x86_64-static";
    src = pkgs.fetchurl {
      url = "https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-x86_64-static";
      sha256 = "sha256-mH9FvYq/K0VshlS4KmqU8Z2Yp6R9y6a/TclBIdtC32o=";
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/qemu-x86_64
      chmod +x $out/bin/qemu-x86_64
    '';
  };
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

      registrations = {
        # General pwn challenges
        x86_64-linux = {
          interpreter = "${qemu-x86_64-static}/bin/qemu-x86_64";
          fixBinary = true;
          wrapInterpreterInShell = false;
          magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
          mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
        };
      };
    };

  };
}
