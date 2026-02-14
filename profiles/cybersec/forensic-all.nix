# A collection of tools used in cybersec forensics challenges
{ profiles, ... }:
{
  imports = with profiles.cybersec.forensic; [
    audio
    disk
    files
    misc
    networking
    stego
  ];
}
