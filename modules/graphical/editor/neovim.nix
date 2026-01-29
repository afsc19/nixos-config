# Discord configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.editor.neovim;
in
{
  options.modules.graphical.editor.neovim.enable = mkEnableOption "neovim";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      neovim
    ];
  };
  # TODO add lazyvim+extensions
}