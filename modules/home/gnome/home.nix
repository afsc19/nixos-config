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
    
    # TODO 
    distrobox # + podman?
    docker
    #vmware
    #kvm

    # TODO Move themes to an independent repo



  ];



}