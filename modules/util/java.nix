# Java
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.util.java;
in
{
  options.modules.util.java.enable = mkEnableOption "Java";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jdk
    ];

    environment.sessionVariables = {
      _JAVA_OPTIONS = "-Dsun.java2d.uiScale=2.0";
    };
  };
}
