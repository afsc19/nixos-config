# An arm64 VPS
{
  config,
  pkgs,
  profiles,
  lib,
  ...
}:
{

  # --- Time ---
  time.timeZone = "Europe/Madrid";

  modules = {
    # Audio enabled in the corresponding profile.
    # Nothing graphical except nvim
    graphical.editor.neovim.base.enable = true;
    services = {
      monitor.uptimewire.enable = true;
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

  # Don't use network manager since oracle cloud poorly supports it
  networking.networkmanager.enable = lib.mkForce false;
  networking.useDHCP = true;
  networking.useNetworkd = true;
  systemd.network.enable = true;


  my.networking.wiredInterface = "enp0s6";
  # No wireless interface
  my.hardware = {
    laptop = false;
    batteryPowered = false;
  };
  my.security.fido2.enable = false;

  # --- Firewall ---
  # Open ports in the firewall.
  #networking.firewall.allowedTCPPorts = [ ... ];
  networking.firewall.interfaces.${config.my.networking.wiredInterface}.allowedTCPPorts = with lib.my.ports; [
    ssh
    http
    https
  ];
  # For Chromecast from chrome (defined in brave.nix)
  #networking.firewall.allowedUDPPortRanges = [ { from = 32768; to = 60999; } ];
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;

  systemd.timers.check-calidor-wakeup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "08:00";
      Persistent = true;
    };
  };

  systemd.services.check-calidor-wakeup = {
    script = ''
      
      if ${pkgs.iputils}/bin/ping -c 1 ${lib.my.uptimewire.fleet.calidor.ip} >/dev/null; then
        ${pkgs.curl}/bin/curl -H "Content-Type: application/json" \
          -d '{"content": "✅ Calidor is UP at 8:00 AM"}' \
          "$(${pkgs.coreutils}/bin/cat ${config.age.secrets.grafanaDiscordWebhook.path})"
      fi
    '';
    serviceConfig.Type = "oneshot";
  };


  system.stateVersion = "25.11";
}
