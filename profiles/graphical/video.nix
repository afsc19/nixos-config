# Apps to view videos
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs.unstable; [
    vlc # Just vlc for now
  ];

}
