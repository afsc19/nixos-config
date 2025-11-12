{ configs, pkgs, lib, inputs, modulePaths, ... }:

{
  imports = with profiles
  

  nix.optimise.automatic = true;


  # --- Bootloader ---
  boot.loader.systemd-boot.enable = false; # disable systemd-boot
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev"; # for UEFI systems
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true; # to detect Windows and Fedora automatically
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # --- Network ---
  networking.hostName = "unkown";
  networking.networkmanager.enable = true; 

  # --- Bluetooth ---
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # --- Sound ---
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    #isDefault
    #wireplumber.enable= true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # --- Time ---
  time.timeZone = "Europe/Lisbon";
  
  # --- Region/Locale ---
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "pt_PT.UTF-8/UTF-8" ];
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_PT.UTF-8";
    LC_IDENTIFICATION = "pt_PT.UTF-8";
    LC_MEASUREMENT = "pt_PT.UTF-8";
    LC_MONETARY = "pt_PT.UTF-8";
    LC_NAME = "pt_PT.UTF-8";
    LC_NUMERIC = "pt_PT.UTF-8";
    LC_PAPER = "pt_PT.UTF-8";
    LC_TELEPHONE = "pt_PT.UTF-8";
    LC_TIME = "pt_PT.UTF-8";
  };


  # --- Input ---
  services.xserver = {
    exportConfiguration = true; # link /usr/share/X11/ properly
    xkb.layout = "us,pt";
    xkb.options = "grp:win_space_toggle";
    xkb.variant = "qwerty_digits";
  };
  services.gnome3.gsettings = {
    ["org.gnome.desktop.input-sources"] = {
      sources = [
        ['xkb', 'us']
        ['xkb', 'pt']
      ];
    };
  };

  # --- Fonts ---
  fonts.packages = with pkgs; [
    font-awesome
    noto-fonts-emoji
    # TODO Pick a font
    #(nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "Iosevka"  ]; })
  ];

  # --- Services ---
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # Flatpak
  services.flatpak.enable = true;
  # locate
  services.locate.enable = true;
  # Enable CUPS to print documents.
  services.printing.enable = true;
  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;
  services.libinput.touchpad.tapping = true; #tap





  modules = {
    graphical = {
      gnome.enable = true;
      gtk.enable = true;
    }
    laptop = {
      battery.enable = true;
    }
    mobile = {
      android-tools.enable = true;
    }
    shell = {
      git.enable = true;
      yazi.enable = true;
      zsh.enable = true;
    }
  }

  



  # --- Firewall ---
  # Open ports in the firewall.
  #networking.firewall.allowedTCPPorts = [ ... ];
  # For Chromecast from chrome
  networking.firewall.allowedUDPPortRanges = [ { from = 32768; to = 60999; } ];
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  #system.stateVersion = "22.11"; # Did you read the comment?
  # TODO set this stateVersion

  


}