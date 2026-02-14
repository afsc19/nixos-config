# Tools for reverse engineering
{
  hm,
  pkgs,
  ...
}:
let
  hasPython = config.modules.util.python.enable;
in
{
  hm.home.packages = with pkgs.unstable; [
    # Manually download portswigger and caido
    
  ];

  hm.home.shellAliases = mkIf hasPython {
    urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
    urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
  };
}