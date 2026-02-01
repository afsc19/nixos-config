
# Configurations for personal systems
{
  pkgs,
  config,
  lib,
  secrets,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.personal;

in
{
  options.modules.personal.enable = mkEnableOption "Personal Configs";

  config = mkIf cfg.enable {
    age.secrets = {
      sylvaKey.file = secrets.personal.sylvaKey;
      pwncollegeKey.file = secrets.personal.pwncollegeKey;
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
          IdentityFile = [ "${config.age.secrets.sylvaKey.path}" ];
          extraOptions = {
            IdentitiesOnly = "yes";
          };
        };
        "world.sylva sylva.world" = {
          hostname = "world.sylva.andrecadete.com";
          user = "ubuntu";
          IdentityFile = [ "${config.age.secrets.sylvaKey.path}" ];
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
          IdentityFile = [ "${config.age.secrets.pwncollegeKey.path}" ];

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
      xkb.variant = "qwerty_digits";
    };
    hm.dconf.settings = {
      "org/gnome/desktop/input-sources" = {
        sources = [
          [ "xkb" "us" ]
          [ "xkb" "pt" ]
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


  };
}