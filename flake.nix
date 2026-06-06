{
  description = "AFSC19 flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    home = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Input for Nixcord (Discord clients configs for NixOS/Home Manager)
    nixcord = {
      url = "github:FlameFlag/nixcord/dev"; # TODO temporary fix for #201 - https://github.com/FlameFlag/nixcord/issues/201

      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    # Secure boot systemd-boot
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

    # From diogotcorreia:
    # pwndbg has been removed from nixpkgs, so we use it here to
    # allow it to be cached and re-exported for my ctf flake
    # https://github.com/NixOS/nixpkgs/pull/380600
    pwndbg = {
      url = "github:pwndbg/pwndbg";
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

    dedsec-grub-theme = {
      url = "gitlab:VandalByte/dedsec-grub-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hires-ti = {
      url = "github:yelanxin/hiresTI";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ida-pro-overlay = {
      url = "github:msanft/ida-pro-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    binaryninja = {
      url = "github:jchv/nix-binary-ninja";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    angr-management = {
      url = "github:angr/angr-management";
      flake = false;
    };

    # QRookie
    glaumar_repo = {
      url = "github:glaumar/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # MemProcFS
    dmatools = {
      url = "github:tie-infra/dmatools";
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
          pwndbg = inputs.pwndbg.packages.${system}.default;
        };

      overlays = (mkOverlays ./overlays) // {
        extraPkgs = _final: prev: (extraPackages { system = prev.stdenv.hostPlatform.system; });
      };
      pkgs = mkPkgs system overlays;
      nixosConfigurations = mkHosts ./hosts {
        inherit extraArgs overlays;
        systems = {
          sylva = "aarch64-linux";
        };
        extraModules = [
          {
            hardware.enableRedistributableFirmware = true;
          }
          inputs.home.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
            };
          }
          # inputs.impermanence.nixosModules.impermanence
          inputs.binaryninja.nixosModules.binaryninja
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.dedsec-grub-theme.nixosModule
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
        # Watchout the --edit for automatic removal
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
