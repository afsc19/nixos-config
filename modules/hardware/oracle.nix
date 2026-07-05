# A module for Oracle Cloud Infrastructure instances
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.hardware.oracle;
in
{
  options.modules.hardware.oracle.enable = mkEnableOption "Oracle OCI tweaks";

  config = mkIf cfg.enable {
    # Block metadata IP for security on VPS (both host and forwarded/docker traffic)
    networking.firewall.extraCommands = ''
      iptables -I OUTPUT -d 169.254.169.254 -j DROP
      iptables -I FORWARD -d 169.254.169.254 -j DROP
    '';

    # Quicker bootloader
    boot.loader.timeout = 2;
  };
}
