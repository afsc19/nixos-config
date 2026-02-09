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

    hm.home.packages = with pkgs; [
      tokyonight-gtk-theme
      papirus-icon-theme
      bibata-cursors
    ];

    # --- GTK customization ---
    hm.gtk = {
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

      gtk3.bookmarks = [
        "file:/// Root"
      ];

      gtk4.extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
          gtk-cursor-theme-name=Bibata-Modern-Classic
        '';
      };
    };
  };
}