{ config, pkgs, user, home-manager, ... }:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{

  # Allow "unfree" licenced packages
  nixpkgs.config = { allowUnfree = true; };


  # Home Manager needs a bit of information about you and the paths it should manage.
  programs.home-manager.enable = true;
  home.username = "${user}";
  home.homeDirectory = "/home/${user}";
  # TODO set this stateVersion
  #home.stateVersion = "23.05";


  

    #gnome outside gnome
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
	      theme = "Tokyo Night";
      };
      # TODO add keybindings
      #"org/gnome/desktop/wm/keybindings" = {
      #  close = ["<Super>q"];
      #  maximize = "<Super>f";
      #  minimize = ["<Super>comma"];
      #};
    };
  };




  home.packages = with pkgs; [
    # Text editors
    vscode-with-extensions
    neovim

    # Browsers
    zen
    chrome

    # GTK customization
    #papirus-icon-theme
    #bibata-cursors
    #tokyonight-gtk-theme

    # File Management
    yazi

    # Yazi dependencies

    # Chatting
    equibop
    discord # Backup

    # Email
    #thunderbird


    # File scraping
    binwalk
    foremost
    


     #########System#########
     kitty
     poweralertd
     dbus
     gnome-browser-connector
     cudatoolkit
     gnomeExtensions.gsconnect
     #gnomeExtensions.legacy-gtk3-theme-scheme-auto-switcher
     #gnome-network-displays
     ###apps###
     discord
     #thunderbird
  ];



}