# Targets to use in prometheus' blackbox
{ lib, ... }:
{
  blackbox = {
    ctfchalls = {
      targets = [
        "sqli1"
        "sqli2"
        "sqli3"
        "cmd1"
        "sxss1"
        "sxss2"
        "rxss1"
        "rxss2"
      ];
      prefix = "https://";
      suffix = ".challs.ctf.andrecadete.com";
    };
  };
}