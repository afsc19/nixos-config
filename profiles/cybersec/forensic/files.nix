# File scraping utils
{
  ...
}:
{
  hm.home.packages = with pkgs; [
    strings # Redefined from shell/essential, just in case
    binwalk
    foremost
    exiftool
  ];
}