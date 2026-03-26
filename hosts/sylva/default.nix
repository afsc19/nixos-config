# An arm64 VPS
{
  config,
  pkgs,
  profiles,
  lib,
  secrets,
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
      nginx = {
        enable = true;
        useEncryptedVhosts = builtins.pathExists ../../secrets/sylva/nginxVhosts.age;
        acmeCerts = [
          {
            domain = "andrecadete.com";
            extraDomainNames = [ "*.andrecadete.com" ];
            dnsProvider = "cloudflare";
          }
          {
            domain = "ctf.andrecadete.com";
            extraDomainNames = [
              "*.ctf.andrecadete.com"
              "*.chall.ctf.andrecadete.com"
            ];
            dnsProvider = "cloudflare";
          }
        ];
      };
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
      java.enable = true;
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
  
  environment.systemPackages = with pkgs; [
    udev
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
  # Block metadata IP for security on VPS
  networking.firewall.extraCommands = ''
    iptables -I OUTPUT -d 169.254.169.254 -j DROP
  '';


  networking.firewall.allowedTCPPortRanges = [ { from = 25550; to = 25559; } ];
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

  # Filesystem mounts
  # ytdl-material
  {
  fileSystems."/mnt/ytdl-store" = {
    device = "/srv/ytdl.img";
    fsType = "ext4";
    options = [ "loop" ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/ytdl-store/audio 0755 root root -"
    "d /mnt/ytdl-store/video 0755 root root -"
    "d /mnt/ytdl-store/subscriptions 0755 root root -"
    "d /mnt/ytdl-store/users 0755 root root -"
    "d /mnt/ytdl-store/db 0755 root root -"
  ];
}


  age.secrets.cloudflareDnsApiToken = {
    file = secrets.host.cloudflareDnsApiToken;
    owner = "acme";
    group = "acme";
    mode = "0400";
  };

  security.acme.defaults.email = "afsc.dev@gmail.com";
  security.acme.defaults.environmentFile = config.age.secrets.cloudflareDnsApiToken.path;

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
