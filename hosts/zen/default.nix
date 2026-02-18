# Laptop PC
{
  profiles,
  ...
}:

{

  # --- Network ---
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
      torrenting.enable = true;
    };
    laptop = {
      battery.enable = true;
      bluetooth.enable = true;
      touchpad.enable = true;
    };
    services = {
      # Nebula (VPN)
      nebula.enable = true;
      openvpn.enable = true;
    };
    shell = {
      git.enable = true;
      yazi = {
        enable = true;
        installDependencies = true;
      };
      zsh.enable = true;
    };
    util = {
      python.enable = true;
    };
    # Virtualization enabled in the laptop-virtualization profile
    virtualization = {
      distrobox = {
        enable = true;
        defaultBoxes = [
          {
            name = "arch";
            image = "docker.io/library/archlinux:latest";
          }
          {
            name = "kali";
            image = "docker.io/kalilinux/kali-rolling";
          }
        ];
      };
    };
    hardware = {
      razer.enable = true;
      intel.enable = true;
    };
    personal.enable = true;
    plymouth = {
      enable = true;
      themeName = "glitch";
    };
    thunderbolt.enable = true;
    xdg.enable = true;
  };

  imports = with profiles; [
    cybersec.all

    graphical.browsers
    graphical.discord
    graphical.disk-utils
    graphical.editors
    graphical.games
    graphical.neovim-personal
    graphical.video

    mobile.android-tools

    security.agenix
    security.securegrub

    services.ssh
    shell.essential
    audio
    laptop-virtualization
  ];

  my.networking.wiredInterface = "eth1";
  my.networking.wirelessInterface = "wlo1";
  my.hardware = {
    laptop = true;
    batteryPowered = true;
    batteryChargeLimit = 75;
    batteryChargeThresholdRange = 3;
  };
  boot.loader.timeout = 200;

  # --- Firewall ---
  # Open ports in the firewall.
  #networking.firewall.allowedTCPPorts = [ ... ];
  # For Chromecast from chrome (defined in brave.nix)
  #networking.firewall.allowedUDPPortRanges = [ { from = 32768; to = 60999; } ];
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;

  system.stateVersion = "25.11";
}
