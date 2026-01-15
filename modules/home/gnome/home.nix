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

    # Yazi dependencies?

    # Email
    thunderbird


    # File scraping
    binwalk
    foremost

    # Audio
    #sonic-visualizer
    #audacity
    #ffmpeg
    #exiftool
    #

    # Rev
    #ghidra
    #binary-ninja
    #ida

    # Steg
    #zsteg
    #stegoveritas
    #stegsolve

    # Brainfuck
    #beef

    #portswigger
    #caido?

    # TODO change gnome alt+tab to include windows from the same app

    # TODO 
    distrobox # + podman?
    docker
    #vmware
    #kvm

    # TODO Move themes to an independent repo

    # TODO add thunderbolt daemon
    # TODO add tidal app? Or use brave for drm?



  ];



}