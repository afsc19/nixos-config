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

  ptyxisTheme = "Argonaut";
  ptyxisProfileUUID = "23f46f5c-8d19-4c07-acab-7d4323234252";
in
{
  options.modules.graphical.gnome.enable = mkEnableOption "GNOME";

  config = mkIf cfg.enable {

    # --- Services ---
    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable GNOME (modern option)
    services.desktopManager.gnome.enable = true;
    # Enable Gnome login
    services.displayManager.gdm.enable = true;
    services.displayManager.gdm.wayland = true;

    # Desktop plumbing that GNOME expects
    programs.dconf.enable = true; # system dconf support
    services.gvfs.enable = true; # Trash, MTP, SMB, etc.
    services.gnome.gnome-keyring.enable = true; # Secret storage + SSH/GPG integration
    #services.power-profiles-daemon.enable = true;# Power management in GNOME

    # Portals for GNOME (file pickers, screencast)
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

    # Nice-to-have GNOME tools
    environment.systemPackages =
      (with pkgs; [
        # tools
        sushi # quick preview in Nautilus (Space)
        gnome-tweaks # tweak tool
        seahorse # GUI for keyring
        ptyxis
      ]) ++ (with pkgs.gnomeExtensions; [
        # extensions
        tiling-shell # helps tiling
        caffeine # dont sleep
        blur-my-shell # modern background blur
        system-monitor # vitals on navbar
        clipboard-history
        user-themes
        dash-to-dock
      ]);
    # Exclude gnome default packages
    environment.gnome.excludePackages =
      (with pkgs; [
        # gnome-photos
        gnome-tour
        # cheese # webcam tool
        # gnome-terminal # default terminal
        gnome-music
        epiphany # web browser
        # gedit # text editor
        # geary # email reader
        # evince # document viewer
        # gnome-characters
        totem # video player
        tali # poker game
        iagno # go game
        hitori # sudoku game
        atomix # puzzle game
        # rygel
        yelp
        # gnome-logs
        # gnome-clocks
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

      "org/gnome/Ptyxis" = {
        default-profile-uuid = ptyxisProfileUUID;
        profile-uuids = [ ptyxisProfileUUID ];
      };

      "org/gnome/Ptyxis/Profiles/${ptyxisProfileUUID}" = {
        label = "Default theme";
        palette = ptyxisTheme;
      };

      "org/gnome/shell/extensions/system-monitor" = {
        show-cpu = true;
        show-download = true;
        show-memory = true;
        show-swap = false;
        show-upload = false;
      };

      "org/gnome/shell/extensions/clipboard-history" = {
        history-size = 100000;
      };

      "org/gnome/shell" = {
        enabled-extensions = [
          "dash-to-dock@micxgx.gmail.com"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "tilingshell@ferrarodomenico.com"
          "caffeine@patapon.info"
          "blur-my-shell@aunetx"
          "system-monitor@gnome-shell-extensions.gcampax.github.com"
          "clipboard-history@alexsaveau.dev"
        ];
        # Find system apps in: /run/current-system/sw/share/applications
        # Find home-manager apps in: ~/.local/state/home-manager/gcroots/current-home/home-path/share/applications
        favorite-apps = [
          "zen-beta.desktop"
          "org.gnome.Ptyxis.desktop"
          "equibop.desktop"
          "brave-browser.desktop"
          "discord.desktop"
          "virt-manager.desktop"
          "vmware-workstation.desktop"
          "org.gnome.Nautilus.desktop"
          "org.gnome.Settings.desktop"
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

    # Also use flatpak
    hm.services.flatpak = {
      enable = true;
      packages = [
        "org.gnome.baobab" # Usage Disk Analyzer
      ];
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
