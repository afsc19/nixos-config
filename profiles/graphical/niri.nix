# Niri + Noctalia Desktop Environment
{
  inputs,
  pkgs,
  config,
  lib,
  configDir,
  ...
}:
let
  ptyxisTheme = "Argonaut";
  ptyxisProfileUUID = "23f46f5c-8d19-4c07-acab-7d4323234252";
in
{
  programs.niri.enable = true;

  programs.noctalia-greeter = {
    enable = true;
    greeter-args = "-- --session niri";
    settings = {
      session.default = "niri";
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
        path = "${pkgs.bibata-cursors}/share/icons";
      };
      keyboard = {
        layout = "us";
      };
      appearance.password_style = "random";
      auth.allow_empty_password = false;
    };
  };

  # TODO some people do this, lemme test without it first
  # users.users.greeter = {
  #   isSystemUser = true;
  #   group = "greeter";
  #   home = "/var/lib/greeter";
  #   createHome = false;
  # };
  # users.groups.greeter = { };

  hm.xdg.configFile."niri/config.kdl".source = ../../config/niri/config.kdl;
  hm.imports = [
    inputs.noctalia.homeModules.default
  ];
  hm.programs.noctalia = {
    enable = true;
    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Ayu";
      };
      wallpaper = {
        enabled = true;
        directory = "${configDir}/wallpapers";
        default.path = "${configDir}/wallpapers/dedsec1.jpg";
      };
      backdrop.enabled = true;
      battery.warning_threshold = 10;
      calendar.account.personal_google = {
        type = "google";
        name = "personal";
      };
      shell = {
        niri_overview_type_to_launch_enabled = true;
        time_format = "{:%H:%M:%S}";
        greeter_sync.auto_sync = true;
      };
      widget.clock.format = "{:%H:%M:%S}";
      lockscreen = {
        enabled = true;
        blurred_desktop = true;
        blur_intensity = 0.7;
        tint_intensity = 0.4;
      };
      lockscreen_widgets = {
        enabled = true;
        widget_order = [ "clock" ];
        widget.clock = {
          type = "clock";
          cx = 200.0;
          cy = 80.0;
          settings = {
            clock_style = "digital";
            format = "{:%H:%M:%S}";
            background = false;
            shadow = true;
          };
        };
      };
      idle = {
        pre_action_fade_seconds = 5.0;
        behavior_order = [ "dim_backlight" "idle_notification" "lock" "screen-off" "suspend" ];
        behaviour = {
          dim_backlight = {
            timeout = 180;
            action = "command";
            command = "brightnessctl -s set 10%";
            resume_command = "brightnessctl -r";
            enabled = true;
          };
          idle_notification = {
            timeout = 545;
            action = "command";
            command = "notify-send 'Idle' 'Going idle'";
            resume_command = "notify-send 'Idle' 'Back from idle'";
          };
          lock = {
            timeout = 600;
            action = "lock";
            enabled = true;
          };
          screen-off = {
            timeout = 660;
            action = "screen_off";
            enabled = true;
          };
          suspend = {
            timeout = 900;
            action = "lock_and_suspend";
          };
        };
      };
    };
    validateConfig = true; # not necessary in nix, but it's here in case I change my mind
  };

  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # noctalia widgets
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;
  services.gvfs.enable = true; # nautilus file manager

  xdg.portal = {
    enable = true;
    config.common.default = "*";
    config.niri = {
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome # Niri screencasts
      pkgs.xdg-desktop-portal-gtk # standard dialogues
    ];
  };

  # Custom systemd user unit to launch polkit-gnome (that was gnome's job)
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # 7. Utilities & Environment Variables
  environment.systemPackages = with pkgs; [
    nautilus # file manager
    sushi # file previewer
    seahorse # graphical keyring manager
    ptyxis
    wl-clipboard
    wdisplays
    xwayland-satellite
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };


  # fallback dconf settings
  hm.dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Catppuccin1-Yellow-Dark";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Bibata-Modern-Classic";
      clock-show-seconds = true;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
    };

    # ptyxis style
    "org/gnome/Ptyxis" = {
      default-profile-uuid = ptyxisProfileUUID;
      profile-uuids = [ ptyxisProfileUUID ];
    };

    "org/gnome/Ptyxis/Profiles/${ptyxisProfileUUID}" = {
      label = "Default theme";
      palette = ptyxisTheme;
    };
  };

  # ptyxis
  xdg.terminal-exec = {
    enable = true;
    settings = {
      default = [ "org.gnome.Ptyxis.desktop" ];
    };
  };

  hm.home.sessionVariables = {
    TERMINAL = "ptyxis";
    # use GNOME Secret Service keyring by gnome-keyring-daemon as org.freedesktop.secrets
    XDG_CURRENT_DESKTOP = "niri:GNOME";
  };
}
