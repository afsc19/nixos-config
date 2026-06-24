# Targets to use in prometheus' blackbox
{ ... }:
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
        "csrf3"
        "csrf3-hoster"
        "ssrf1"
        "ssrf1-hard"
        "ssrf2"
        "ssrf3"
        "domxss1"
        "pp1"
        "pp-lab"
        "pp2"
        "sspp1"
        "sspp2"
        "sspp3"
        "ssti1"
        "ssti2"
        "ssti3"
      ];
      prefix = "https://";
      suffix = ".chall.ctf.andrecadete.com";
    };
  };
}
