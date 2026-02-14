# Steganography utils
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    stegsolve
    zsteg
    steghide
    stegseek
  ];
}
