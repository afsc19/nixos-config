{ config, pkgs, user, home-manager, ... }:
let
  # home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{









  home.packages = with pkgs; [
    # Text editors
    # TODO move to a module
    # neovim

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

    # TODO move to virtualization profile or dedidcated modules 
    #vmware
    #kvm

    # TODO add thunderbolt daemon



  ];



}