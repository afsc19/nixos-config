# File scraping utils
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    binutils # For strings, also defined in modules.shell.essential
    binwalk
    foremost
    exiftool
  ];
}
