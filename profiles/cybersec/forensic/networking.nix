# Networking utils
{
  ...
}:
{
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark; # use Qt version instead of CLI version
  };

  usr.extraGroups = [
    "wireshark"
    "dialout" # access USB TTY devices without sudo
  ];


}