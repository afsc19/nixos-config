# Some games
{
  inputs,
  lib,
  pkgs,
  ...
}:
{

  modules.graphical.editor = {
    vscode.enable = true;
    neovim.base.enable = true;
  };
}
