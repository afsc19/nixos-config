# User everything for cybersec
{ ... }:
{
  import = with profiles.cybersec; [
    forenisc
    pwn
    reverse
    web
  ];
}