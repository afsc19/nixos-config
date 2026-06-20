# OpenCode - terminal-based AI coding agent
# https://opencode.ai
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.shell.opencode;
in
{
  options.modules.shell.opencode.enable = mkEnableOption "OpenCode";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs.unstable; [
      opencode
      opencode-desktop
    ];
  };
}
