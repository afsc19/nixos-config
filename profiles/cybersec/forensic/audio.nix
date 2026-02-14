# Audio utils
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    qsstv
    ffmpeg

    # Graphical
    audacity
    sonic-visualiser
  ];
}
