# File scraping utils
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    binutils # For strings, also defined in modules.shell.essential
    exiftool # Also defined in modules.shell.essential

    binwalk
    foremost
    unblob

    # pdf
    pdfcrack
    poppler
  ];
}
