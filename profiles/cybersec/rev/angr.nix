# Angr Management
{
  pkgs,
  ...
}:
let
in {
  hm.home.packages = with pkgs; [
    (writeShellScriptBin "angr-management" ''
      exec env -u QT_STYLE_OVERRIDE -u QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE=Fusion ${my.cybersec.angr-management}/bin/angr-management "$@"
    '')
  ];
}
