# An arm64 VPS
{
  pkgs,
  profiles,
  ...
}:

{
  # --- Network ---
  networking.networkmanager.enable = true;

  # --- Time ---
  time.timeZone = "Atlantic/Azores";

  modules = {
    # Audio enabled in the corresponding profile.
    # Nothing graphical except nvim
    graphical.editor.neovim.base.enable = true;
    services = {
      # Nebula (VPN)
      nebula = {
        enable = true;
        isLighthouse = true;
        firewall.inbound = [
          {
            port = "any";
            proto = "any";
            group = "afsc";
          }
        ];
      };
      # TODO automatic append-only backups
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
    virtualization = {
      docker.enable = true;
    };
    # plymouth.enable = true;
  };

  imports = with profiles; [
    security.agenix

    services.ssh
    shell.essential
  ];

  boot.loader.systemd-boot.enable = true;

  my.networking.wiredInterface = "eth1";
  # No wireless interface
  my.hardware = {
    laptop = false;
    batteryPowered = false;
  };

  # --- Firewall ---
  # Open ports in the firewall.
  #networking.firewall.allowedTCPPorts = [ ... ];
  # For Chromecast from chrome (defined in brave.nix)
  #networking.firewall.allowedUDPPortRanges = [ { from = 32768; to = 60999; } ];
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;

  system.stateVersion = "25.11";
}
