# Sparx Systems Enterprise Architect (wine)
# The installer is read from my.softwareDirectory, use ENTERPRISE_ARCHITECT_MSI override
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.enterprise-architect;
in
{
  options.modules.graphical.enterprise-architect.enable =
    mkEnableOption "Sparx Enterprise Architect (via Wine)";

  config = mkIf cfg.enable {
    hm.home.packages = [
      # writeShellApplication only runs buildCommand apparently
      (pkgs.my.enterprise-architect.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
        buildCommand = (old.buildCommand or "") + ''
          wrapProgram $out/bin/enterprise-architect \
            --set-default ENTERPRISE_ARCHITECT_MSI "${config.my.softwareDirectory}/enterprise_architect/easetupfull_x64.msi"
        '';
      }))
      pkgs.wineWow64Packages.stable
      pkgs.winetricks
    ];

    # Carlito is required by Sparx's Linux guide (diagram text rendering).
    fonts.packages = with pkgs; [
      carlito
    ];
  };
}
