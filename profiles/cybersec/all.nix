# User everything for cybersec
{ profiles, ... }:
{
  imports = with profiles.cybersec; [
    forensic-all
    pwn
    reverse
    web
  ];
}
