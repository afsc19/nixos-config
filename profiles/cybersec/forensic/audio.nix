# Audio utils
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    my.cybersec.sstv
    ffmpeg

    # Graphical
    audacity
    sonic-visualiser
  ];
}
