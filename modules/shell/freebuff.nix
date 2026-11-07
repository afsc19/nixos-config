# Freebuff - free terminal-based AI coding agent by Codebuff
# https://freebuff.com
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.shell.freebuff;
in
{
  options.modules.shell.freebuff.enable = mkEnableOption "Freebuff";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.my.freebuff ];
  };
}
