{
  pkgs,
  config,
  lib,
  vscodeAyuThemeDir,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.editor.vscode;

  ayu-high-contrast = pkgs.vscode-utils.buildVscodeExtension {
    name = "ayu-high-contrast-themes";
    src = vscodeAyuThemeDir;
    vscodeExtName = "ayu-high-contrast-themes";
    vscodeExtPublisher = "afsc19";
    vscodeExtUniqueId = "afsc19.ayu-high-contrast-themes";
    version = "1.0.0";
  };
in
{
  options.modules.graphical.editor.vscode.enable = mkEnableOption "vscode";

  config = mkIf cfg.enable {
    hm.programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      extensions = with pkgs.vscode-extensions; [
        # Nix
        bbenoist.nix
        jnoortheen.nix-ide

        # PDFs
        tomoki1207.pdf

        # HEX editor
        ms-vscode.hexeditor

        # CSV colors
        mechatroner.rainbow-csv

        # Themes
        teabyii.ayu
        FranRuizSantaclara.high-contrast-theme

        # Custom theme
        ayu-high-contrast

      ];
      userSettings = {
        "workbench.colorTheme" = "Ayu Dark Bordered High Contrast"; # Custom theme
        "editor.fontSize" = 14;
        "files.refactoring.autoSave" = true;
        # TODO add more settings
      };
    };
  };
}
