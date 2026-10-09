# Claude Code - Anthropic's terminal-based AI coding agent
# https://claude.com/product/claude-code
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.shell.claude-code;
in
{
  options.modules.shell.claude-code.enable = mkEnableOption "Claude Code";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs.unstable; [
      claude-code
    ];
  };
}
