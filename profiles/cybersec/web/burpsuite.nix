# Burp Suite
{
  pkgs,
  config,
  lib,
  ...
}:
let
  burpDir = /. + "${config.my.softwareDirectory}/burp";
  loaderJar = /. + "${toString burpDir}/BurpLoaderKeygen.jar";

  burpPkg = pkgs.my.cybersec.burpsuite.overrideAttrs (old: {
    src = burpDir;
  });
in
{
  assertions = [
    {
      assertion = builtins.pathExists loaderJar;
      message = "BurpSuite files missing! Please place them in ${burpDir}";
    }
  ];

  hm.home.packages = [ burpPkg ];
}
