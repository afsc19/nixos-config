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

  # FIXME temp fix: drop once nixos-unstable has NixOS/nixpkgs@c399e1b7fb
  # ("opencode: fix hash"), which sets this same hash.
  opencode = pkgs.unstable.opencode.overrideAttrs (old: {
    node_modules = old.node_modules.overrideAttrs {
      outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
    };
  });
  opencode-desktop = pkgs.unstable.opencode-desktop.override { inherit opencode; };
in
{
  options.modules.shell.opencode.enable = mkEnableOption "OpenCode";

  config = mkIf cfg.enable {
    environment.systemPackages = [
      opencode
      opencode-desktop
    ];
  };
}
