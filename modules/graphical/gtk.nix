# GTK
{
  pkgs,
  config,
  lib,
  themesDir,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.gtk;
in {
  options.modules.graphical.gtk.enable = mkEnableOption "GTK";

  config = mkIf cfg.enable {

    hm.programs = {
      tokyonight-gtk-theme.enable = true;
      papirus-icon-theme.enable = true;
      bibata-cursors.enable = true;
    }

    # --- GTK customization ---
    gtk = {
      enable = true;
      font.name = "TeX Gyre Adventor 10";

      theme = {
        name = "Catppuccin1-Yellow-Dark";
        package = pkgs.runCommand "catppuccin1-yellow-dark" { } ''
          mkdir -p $out/share/themes
          cp -r ${themesDir}/Catppuccin1-Yellow-Dark $out/share/themes/
        '';
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
      };

      gtk3.extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
          gtk-cursor-theme-name=Bibata-Modern-Classic
        '';
      };

      gtk4.extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
          gtk-cursor-theme-name=Bibata-Modern-Classic
        '';
      };
    };
  }
}