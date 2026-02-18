# Configurations for personal systems
{
  pkgs,
  config,
  lib,
  inputs,
  secrets,
  user,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.personal;
  isGnome = config.modules.graphical.gnome.enable;
in
{
  options.modules.personal.enable = mkEnableOption "Personal Configs";

  config = mkIf cfg.enable {
    age.secrets = {
      sylvaKey = {
        file = secrets.personal.sylvaKey;
        owner = user;
      };
      pwncollegeKey = {
        file = secrets.personal.pwncollegeKey;
        owner = user;
      };
    };

    # ssh client config
    hm.programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = { };

        # Use if TERM isnt recognized on older  servers
        # "* !apollo !bacchus".setEnv = {
        #   TERM = "xterm-256color";
        # };

        sylva = {
          hostname = "sylva.andrecadete.com";
          user = "ubuntu";
          identityFile = [ "${config.age.secrets.sylvaKey.path}" ];
          extraOptions = {
            IdentitiesOnly = "yes";
          };
        };
        "world.sylva sylva.world" = {
          hostname = "world.sylva.andrecadete.com";
          user = "ubuntu";
          identityFile = [ "${config.age.secrets.sylvaKey.path}" ];
          extraOptions = {
            IdentitiesOnly = "yes";
          };
        };
        sigma = {
          hostname = "sigma.ist.utl.pt";
          user = "ist1114254";
          extraOptions = {
            PubkeyAuthentication = "no";
          };
        };

        "rnl cluster.rnl" = {
          hostname = "cluster.rnl.tecnico.ulisboa.pt";
          user = "ist1114254";
          extraOptions = {
            PubkeyAuthentication = "no";
          };
        };

        pwncollege = {
          hostname = "pwn.college";
          user = "hacker";
          identityFile = [ "${config.age.secrets.pwncollegeKey.path}" ];

          extraOptions = {
            IdentitiesOnly = "yes";
          };
        };

      };

      extraConfig = ''
        VerifyHostKeyDNS yes
      '';
    };
    # --- Input ---
    services.xserver = {
      exportConfiguration = true; # link /usr/share/X11/ properly
      xkb.layout = "us,pt";
      xkb.options = "grp:win_space_toggle";
    };
    hm.dconf.settings = mkIf isGnome {
      "org/gnome/desktop/input-sources" = {
        sources = [
          (inputs.home.lib.hm.gvariant.mkTuple [
            "xkb"
            "us"
          ])
          (inputs.home.lib.hm.gvariant.mkTuple [
            "xkb"
            "pt"
          ])
        ];
        xkb-options = [ "grp:win_space_toggle" ];
      };
    };

    # --- Fonts ---
    fonts.packages = with pkgs; [
      font-awesome
      noto-fonts-color-emoji
      # Recommended Nerd Fonts
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
      nerd-fonts.symbols-only
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

  };
}
