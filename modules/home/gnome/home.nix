{ config, pkgs, user, home-manager, ... }:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{

  # Allow "unfree" licenced packages
  nixpkgs.config = { allowUnfree = true; };









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