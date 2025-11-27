# Some games
{
  inputs,
  lib,
  pkgs,
  ...
}:
{

  imports = with profiles [
    graphical.browser.zen;
    graphical.browser.brave;
  ];
}