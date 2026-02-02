# TODO propagate to sylva

# Base yourself on this config:
# Laptop PC
{ configs, pkgs, lib, inputs, modulePaths, profiles, ... }:

{


  # --- Bootloader ---
  #boot.loader.systemd-boot.enable = false; # disable systemd-boot
  #boot.loader.grub.enable = true;
  #boot.loader.grub.version = 2;
  #boot.loader.grub.device = "nodev"; # for UEFI systems
  #boot.loader.grub.efiSupport = true;
  #boot.loader.grub.useOSProber = true; # to detect Windows and Fedora automatically
  #boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";


  # --- Network ---
  # Defined in generators.nix - networking.hostName = "zen";
  networking.networkmanager.enable = true; 


  # --- Time ---
  time.timeZone = "Europe/Lisbon";



  modules = {
    # Audio enabled in the corresponding profile.
    graphical = {
      # Browsers enabled in the corresponding profile.
      # Discord enabled in the corresponding profile.
      # Editors enabled in the corresponding profile.
      gnome.enable = true;
      gtk.enable = true;
      qt.enable = true;
      spotify.enable = true;
    };
    laptop = {
      battery.enable = true;
      bluetooth.enable = true;
      touchpad.enable = true;
    };
    services = {
      # Nebula (VPN)
      nebula.enable = true;
    };
    shell = {
      git.enable = true;
      yazi = {
        enable = true;
        installDependencies = true;
      };
      zsh.enable = true;
    };
    personal.enable = true;
    thunderbolt.enable = true;
    xdg.enable = true;
  };



  imports = with profiles; [
    graphical.browsers
    graphical.discord
    graphical.editors
    graphical.games

    mobile.android-tools

    security.agenix
    security.securegrub
    
    shell.essential
    audio
    laptop-virtualization
  ];

  my.networking.wiredInterface = "eth1";
  my.networking.wirelessInterface = "wlo1";
  my.hardware.laptop = true;
  # TODO add my....
  

  



  # --- Firewall ---
  # Open ports in the firewall.
  #networking.firewall.allowedTCPPorts = [ ... ];
  # For Chromecast from chrome (defined in brave.nix)
  #networking.firewall.allowedUDPPortRanges = [ { from = 32768; to = 60999; } ];
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  


}