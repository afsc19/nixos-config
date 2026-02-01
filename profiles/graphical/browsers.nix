# Some games
{
  inputs,
  lib,
  pkgs,
  ...
}:
{

  modules.graphical.browser = {
    zen.enable = true;
    brave.enable = true;
  };
}