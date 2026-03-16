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
        "api1"
        "csrf1"
        "csrf1-hoster"
        "csrf2"
      ];
      prefix = "https://";
      suffix = ".chall.ctf.andrecadete.com";
    };
  };
}