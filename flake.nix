{
  description = "afsc gnome flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    home = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO https://wiki.nixos.org/wiki/Impermanence

    agenix = {
      url = "github:ryantm/agenix/main";
      inputs.nixpkgs.follows = "nixpkgs";

      # we don't use darwin, so we can get rid of it
      inputs.darwin.follows = "";

      # used for home-manager's internal tests only
      inputs.home-manager.follows = "";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote?ref=v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
      # only used for development, so we can get rid of it
      inputs.pre-commit-hooks-nix.follows = "";
      # only used for non-flake setups, so we can get rid of it
      inputs.flake-compat.follows = "";
    };

    # To inspect indexes
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # pwndbg has been removed from nixpkgs, so we use it here to
    # allow it to be cached and re-exported for my ctf flake
    # https://github.com/NixOS/nixpkgs/pull/380600
    pwndbg = {
      url = "github:pwndbg/pwndbg?ref=2025.10.20";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
    };

    themes = {
      url = "github:afsc19/gtk-themes";
      flake = false;
    };

    vscode-ayu-theme = {
      url = "github:afsc19/ayu-high-contrast-themes";
      flake = false;
    };
  };

  outputs =
    inputs@{ ... }:
    let
      inherit (lib.my)
        mkHosts
        mkOverlays
        mkPkgs
        mkProfiles
        mkSecrets
        ;

      user = "afsc";
      userFullName = "Andre";
      system = "x86_64-linux";

      extraArgs = {
        inherit
          user
          userFullName
          ;
        configDir = ./config;
        themesDir = inputs.themes;
        vscodeAyuThemeDir = inputs.vscode-ayu-theme;
      };

      lib = inputs.nixpkgs.lib.extend (
        self: _super:
        import ./lib (
          {
            inherit
              inputs
              nixosConfigurations
              profiles
              pkgs
              secrets
              ;
            lib = self;
          }
          // extraArgs
        )
      );
      extraPackages =
        { system, ... }:
        {
          agenix = inputs.agenix.packages.${system}.default;
          spicetify = inputs.spicetify-nix.legacyPackages.${system};
        };

      overlays = (mkOverlays ./overlays) // {
        extraPkgs = _self: _super: (extraPackages { inherit system; });
      };
      pkgs = mkPkgs overlays;
      nixosConfigurations = mkHosts ./hosts {
        inherit extraArgs;
        # TODO move to profiles
        extraModules = [
          {
            hardware.enableRedistributableFirmware = true;
          }
          inputs.home.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
          inputs.impermanence.nixosModules.impermanence
          inputs.lanzaboote.nixosModules.lanzaboote
        ];
      };
      profiles = mkProfiles ./profiles;
      secrets = mkSecrets ./secrets;
    in
    {
      inherit nixosConfigurations lib overlays;

      # Packages are here so they are built by CI and cached
      packages = {
        x86_64-linux = (lib.filterAttrs (_: v: lib.isDerivation v) pkgs.my) // {
          # inherit (pkgs);
          inherit (inputs.lanzaboote.packages.x86_64-linux) lzbt;
          inherit (inputs.pwndbg.packages.x86_64-linux) pwndbg;
        };
      };

      formatter = {
        # TODO watchout the --edit for automatic removal
        # https://github.com/NixOS/nix/pull/11438#issuecomment-2343378813
        x86_64-linux = pkgs.writeShellScriptBin "formatter" ''
          # If no arguments are passed, default to formatting the whole project
          if [[ $# = 0 ]]; then
            prj_root=$(git rev-parse --show-toplevel 2>/dev/null || echo .)
            set -- "$prj_root"
          fi

          "${lib.getExe pkgs.deadnix}" --hidden --edit "$@"
          "${lib.getExe pkgs.nixfmt-tree}" "$@"
        '';
      };
    };
}

#      pkgs = import nixpkgs {
#        inherit system;
#        config.allowUnfree = true;
#      };
#
#      lib = nixpkgs.lib;
#    in
#    {
#      nixosConfigurations = {
#        #hyprland = nixpkgs.lib.nixosSystem {
#        #  inherit system;
#        #  specialArgs = { inherit user; };
#        #  modules = [
#        #    ./hosts/hyprland/configuration.nix
##
#        #    hyprland.nixosModules.default
#        #    {
#        #      programs.hyprland.enable = true;
#        #      programs.hyprland.xwayland.enable = true;
#        #    }
#        #    home-manager.nixosModules.home-manager
#        #    {
#        #      home-manager.useGlobalPkgs = true;
#        #      home-manager.useUserPackages = true;
#        #      home-manager.extraSpecialArgs = { inherit user; };
#        #      home-manager.users.${user} = import ./modules/home/hyprland/home.nix;
#        #    }
#        #  ];
#        #};
#        gnome = nixpkgs.lib.nixosSystem {
#          inherit system;
#          specialArgs = { inherit user; };
#          modules = [
#            ./hosts/gnome/configuration.nix
#
#            home-manager.nixosModules.home-manager
#            {
#              home-manager.useGlobalPkgs = true;
#              home-manager.useUserPackages = true;
#              home-manager.extraSpecialArgs = { inherit user; };
#              home-manager.users.${user} = import ./modules/home/gnome/home.nix;
#            }
#          ];
#        };
#
#      };
#
#    };
#}
