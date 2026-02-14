# Laptop PC used for server purposes (minimal, no graphical desktop)
{
  configs,
  pkgs,
  lib,
  inputs,
  modulePaths,
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
    # Virtualization enabled in the laptop-virtualization profile
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
  my.networking.wirelessInterface = "wlo1";
  my.hardware = {
    laptop = true;
    batteryPowered = true;

    # This is redundant, since SP4 doesn't support charge thresholds.
    # Remember to use "Battery Limit" in the BIOS to limit the battery to 50%.
    batteryChargeLimit = 75;
    batteryChargeThresholdRange = 3;
  };

  modules.services.nebula.firewall.inbound = [
    {
      port = "any";
      proto = "any";
      group = "afsc";
    }
  ];

  # --- Screen dimming services ---
  systemd.services.enable-screen = {
    description = "Sets the screen brightness to 1 (minimum)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 1 > /sys/class/backlight/*/brightness'";
    };
  };

  systemd.services.disable-screen = {
    description = "Turns the screen off (sets brightness to 0)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 0 > /sys/class/backlight/*/brightness'";
    };
  };

  systemd.timers.disable-screen = {
    description = "Timer for disabling the screen";
    timerConfig = {
      OnBootSec = "2min";
      Unit = "disable-screen.service";
    };
    wantedBy = [ "timers.target" ];
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
