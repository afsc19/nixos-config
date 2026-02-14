# Tools for reverse engineering
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
  hm.home = {
    packages = with pkgs.unstable; [
      # Manually download portswigger and caido
      ungoogled-chromium

    ];

    shellAliases = mkIf hasPython {
      urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
      urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
    };
  };
}
