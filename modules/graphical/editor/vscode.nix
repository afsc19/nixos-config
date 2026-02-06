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
    pname = "ayu-high-contrast-themes";

    unpackPhase = ''
      cp -r $src extension
      chmod -R +w extension
      sourceRoot=extension
    '';
    
    # Manually install the extension since there's no build process
    buildPhase = ''
       runHook preBuild;
       mkdir -p "$out/vscode/extensions/afsc19.ayu-high-contrast-themes"
       cp -r * "$out/vscode/extensions/afsc19.ayu-high-contrast-themes"
       runHook postBuild;
    '';
  };

  userSettings = {
    "workbench.colorTheme" = "Ayu Dark Bordered High Contrast"; # Custom theme
    "editor.fontSize" = 14;
    "files.refactoring.autoSave" = true;
    "files.autoSave" = "afterDelay";

    "github.copilot.enable" = {
      "*" = false;
    };
    "git.autofetch" = true;
    "explorer.confirmDelete" = false;
    "editor.acceptSuggestionOnEnter" = "off";
    "explorer.confirmDragAndDrop" = false;
    "C_Cpp.clang_format_fallbackStyle" = "{BasedOnStyle: Google, IndentWidth: 4, ColumnLimit: 80, AllowShortBlocksOnASingleLine: Empty, AllowShortFunctionsOnASingleLine: Empty, AllowShortIfStatementsOnASingleLine: Never, AllowShortLoopsOnASingleLine: False}";
    "java.referencesCodeLens.enabled" = true;
    "javascript.suggest.completeFunctionCalls" = true;
    "editor.quickSuggestions" = {
      "other" = "off";
    };
    "[java]" = {
      "editor.defaultFormatter" = "redhat.java";
    };
    "[nix]" = {
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
    };
    "[c]" = {
      "editor.defaultFormatter" = "ms-vscode.cpptools";
    };
    "[cpp]" = {
      "editor.defaultFormatter" = "ms-vscode.cpptools";
    };
    "makefile.configureOnOpen" = true;
    "editor.suggest.selectionMode" = "whenTriggerCharacter";
    "chat.tools.terminal.autoApprove" = {
      "zbarimg" = true;
      "strings" = true;
    };
    # TODO add more settings
  };
in
{
  options.modules.graphical.editor.vscode.enable = mkEnableOption "vscode";

  config = mkIf cfg.enable {
    hm.programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          # Nix
          bbenoist.nix
          jnoortheen.nix-ide

          # Java
          redhat.java
          ms-vscode.cpptools

          # PDFs
          tomoki1207.pdf

          # HEX editor
          ms-vscode.hexeditor

          # CSV colors
          mechatroner.rainbow-csv

          # Themes
          teabyii.ayu
          # FranRuizSantaclara.high-contrast-theme

          # Custom theme
          ayu-high-contrast

        ];
        inherit userSettings;
      };
    };

    hm.home.activation.vscodeSettings = {
      after = [ "writeBoundary" ];
      before = [ ];
      data = ''
        userDir=~/.config/Code/User
        rm -f $userDir/settings.json
        cat ${pkgs.writeText "vscode-settings" (builtins.toJSON userSettings)} | ${pkgs.jq}/bin/jq > $userDir/settings.json
        chmod +w $userDir/settings.json
      '';
    };
  };
}
