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
    hardware.oracle.enable = true;
    services = {
      monitor = {
        portainer.enable = true;
        rancher.enable = false;
        uptimewire.enable = true;
      };
      cloudflared = {
        enable = true;
        tunnels = [
          {
            tunnelName = "sylva-andrecadete-com";
            tunnelID = "00425117-9b58-410e-a793-de5560839cb1";
            default = "https://localhost:443";
            ingress = {
              "*.chall.ctf.andrecadete.com" = "https://localhost:443";
            };
          }
        ];
      };
      ctfd.enable = true;
      nginx = {
        enable = true;
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
      docker = {
        enable = true;
        useVirtualization = true;
      };
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

  # ip forwarding for distributed ctf challenges
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = lib.mkForce 1;
  };

  # NAT to favilla
  # networking.nat = {
  #   enable = true;
  #   externalInterface = config.my.networking.wiredInterface;
  #   internalInterfaces = [ "nebula1" ];
  #   forwardPorts = [
  #     {
  #       sourcePort = 50400;
  #       proto = "tcp";
  #       destination = "192.168.100.5:50400";
  #     }
  #   ];
  #   extraCommands = ''
  #     iptables -t nat -A POSTROUTING -d 192.168.100.5 -p tcp --dport 50400 -j MASQUERADE
  #   '';
  # };

  networking.firewall.allowedTCPPortRanges = [
    {
      from = 25550;
      to = 25559;
    }
  ];
  # Open ports in the firewall.
  #networking.firewall.allowedTCPPorts = [ ... ];
  networking.firewall.interfaces.${config.my.networking.wiredInterface} = {
    allowedTCPPorts = with lib.my.ports; [
      ssh
      http
      https

      mc

      # SINFO 2026
      50400
      50401
      50402
      50403
      50404
      50405
      50406
      50407
      50408
      50409
      50410
      50411
      50412
      50413
      50414
      50415
      50416
      50417
      50418
      50419
      50420
    ];
    allowedUDPPorts = with lib.my.ports; [
    ];
  };
  # For Chromecast from chrome (defined in brave.nix)
  #networking.firewall.allowedUDPPortRanges = [ { from = 32768; to = 60999; } ];
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;

  # Filesystem mounts
  # ytdl-material
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

  system.stateVersion = "26.05";
}
