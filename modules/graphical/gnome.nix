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
    programs.dconf.enable = true;                # system dconf support
    services.gvfs.enable = true;                 # Trash, MTP, SMB, etc.
    services.gnome.gnome-keyring.enable = true;  # Secret storage + SSH/GPG integration
    #services.power-profiles-daemon.enable = true;# Power management in GNOME

    # Portals for GNOME (file pickers, screencast)
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

    # Nice-to-have GNOME tools
    environment.systemPackages = (with pkgs; [
      gnome.sushi        # quick preview in Nautilus (Space)
      gnome.gnome-tweaks # tweak tool
      gnome.seahorse     # GUI for keyring & 
    ]);
    # Exclude gnome default packages
    environment.gnome.excludePackages = 
      (with pkgs; [
        gnome-photos
        gnome-tour
      ]) ++ (with pkgs.gnome; [
        cheese # webcam tool
        #gnome-music
        gnome-terminal
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