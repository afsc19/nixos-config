# Web application security tools
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  hasPython = config.modules.util.python.enable;
in
{
  imports = [
    ./burpsuite.nix
  ];

  hm.home = {
    packages = with pkgs.unstable; [
      # Browsers
      ungoogled-chromium
      firefox

      # SQL
      dbeaver-bin
      sqlitebrowser

    ];

    shellAliases = mkIf hasPython {
      urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
      urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
    };
  };
}
