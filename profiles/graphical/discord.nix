# Some games
{
  inputs,
  lib,
  pkgs,
  ...
}:
{

  modules.graphical = {
    equibop.enable = true;

    # backup
    discord.enable = true;
  };
}
