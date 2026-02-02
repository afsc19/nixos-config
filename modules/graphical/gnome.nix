# GNOME dwm
{
  pkgs,
  config,
  lib,
  configDir,
  user,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf escapeShellArg;
  cfg = config.modules.graphical.gnome;

  wallpaper = "file://${configDir}/wallpapers/dedsec1.jpg";
in
{
  options.modules.graphical.gnome.enable = mkEnableOption "GNOME";

  config = mkIf cfg.enable {

    # --- Services ---
    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable GNOME (modern option)
    services.xserver.desktopManager.gnome.enable = true;
    # Enable Gnome login
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.displayManager.gdm.wayland = true;

    # Desktop plumbing that GNOME expects
    programs.dconf.enable = true; # system dconf support
    services.gvfs.enable = true; # Trash, MTP, SMB, etc.
    services.gnome.gnome-keyring.enable = true; # Secret storage + SSH/GPG integration
    #services.power-profiles-daemon.enable = true;# Power management in GNOME

    # Portals for GNOME (file pickers, screencast)
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

    # Nice-to-have GNOME tools
    environment.systemPackages = (
      with pkgs;
      [
        # tools
        gnome.sushi # quick preview in Nautilus (Space)
        gnome.gnome-tweaks # tweak tool
        gnome.seahorse # GUI for keyring &
        ptyxis

        # extensions
        gnomeExtensions.tilingshell # helps tiling
        gnomeExtensions.caffeine # dont sleep
        gnomeExtensions.blur-my-shell # modern background blur
        gnomeExtensions.system-monitor # vitals on navbar
        gnomeExtensions.user-theme

        # TODO customize which are enabled by default (for System extensions that aren't listed here)
      ]
    );
    # Exclude gnome default packages
    environment.gnome.excludePackages =
      (with pkgs; [
        gnome-photos
        gnome-tour
      ])
      ++ (with pkgs.gnome; [
        cheese # webcam tool
        #gnome-music
        gnome-terminal # default terminal
        #gedit # text editor
        epiphany # web browser
        #geary # email reader
        #evince # document viewer
        #gnome-characters
        #totem # video player
        tali # poker game
        iagno # go game
        hitori # sudoku game
        atomix # puzzle game
        #rygel
        yelp
        #gnome-logs
        #gnome-clocks
        gnome-contacts
      ]);
    # Manage shell extensions through the browser
    services.gnome.gnome-browser-connector.enable = true;

    hm.dconf.settings = {
      "org/gnome/desktop/background" = {
        color-shading-type = "solid";
        picture-uri = wallpaper;
        picture-uri-dark = wallpaper;
      };

      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Catppuccin1-Yellow-Dark";
        icon-theme = "Papirus-Dark"; # or Catppuccin icons ?
        cursor-theme = "Bibata-Modern-Classic";
      };

      "org/gnome/shell/extensions/system-monitor" = {
        show-cpu = true;
        show-download = true;
        show-memory = true;
        show-swap = false;
        show-upload = false;
      };

      "org/gnome/shell" = {
        enabled-extensions = [
          "dash-to-dock@micxgx.gmail.com"
          "show-desktop-button@amivaleo"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
        ];
        favorite-apps = [
          # TODO select favorites (pinned on the bottom bar)
          "org.gnome.Nautilus.desktop"
          "firefox.desktop"
          "org.gnome.Terminal.desktop"
          "org.gnome.TextEditor.desktop"
          "gvim.desktop"
          "org.gnome.Extensions.desktop"
          "org.gnome.Settings.desktop"
          "org.gnome.tweaks.desktop"
          "nixos-manual.desktop"
        ];
      };

      "org/gnome/shell/extensions/user-theme" = {
        name = "Catppuccin1-Yellow-Dark"; # Shell theme name from theme dir
      };

      "org/gnome/desktop/wm/keybindings" = {
        switch-windows = [ "<Alt>Tab" ];
        switch-windows-backward = [ "<Shift><Alt>Tab" ];
        switch-applications = [ "<Super>Tab" ];
        switch-applications-backward = [ "<Shift><Super>Tab" ];
        # close = ["<Super>q"];
        # maximize = "<Super>f";
        # minimize = ["<Super>comma"];
      };

      "org/gnome/shell/window-switcher" = {
        current-workspace-only = false;
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Open Terminal";
        command = "ptyxis --new-window"; # or "kgx", "alacritty", etc.
        binding = "<Control><Alt>comma";
      };
    };

    # Enabled by default.
    #polkit Auth Agent
    #systemd = {
    #  user.services.polkit-gnome-authentication-agent-1 = {
    #    description = "polkit-gnome-authentication-agent-1";
    #    wantedBy = [ "graphical-session.target" ];
    #    wants = [ "graphical-session.target" ];
    #    after = [ "graphical-session.target" ];
    #    serviceConfig = {
    #      Type = "simple";
    #      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    #      Restart = "on-failure";
    #      RestartSec = 1;
    #      TimeoutStopSec = 10;
    #    };
    #  };
    #};

  };
}
