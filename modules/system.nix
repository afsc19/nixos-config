# System config common across all hosts, from diogotcorreia
{
  config,
  inputs,
  lib,
  ...
}:
{
  nix.optimise.automatic = true; # replaces nix.settings.auto-optimise-store
  nix = {
    settings = {
      #auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Don't add @wheel here, since it allows for privilege escalation
      # https://github.com/NixOS/nix/issues/9649#issuecomment-1868001568
      trusted-users = [ "root" ];

      # https://jackson.dev/post/nix-reasonable-defaults/
      fallback = true; # skip offline binary-caches (can end up building from source)

      # Use substituters even for trivial derivations
      always-allow-substitutes = true;
    };

    # Lock flake registry to keep it synced with the inputs
    # i.e. used by `nix run pkgs#<package>`
    registry = rec {
      # not using `input.<name>` here in order to not bloat the closure size
      nixpkgs.to = pkgs.to;
      # alias to nixpkgs
      pkgs.to = {
        type = "github";
        owner = "NixOS";
        repo = "nixpkgs";
        inherit (inputs.nixpkgs.sourceInfo) lastModified narHash rev;
      };
      unstable.to = {
        type = "github";
        owner = "NixOS";
        repo = "nixpkgs";
        inherit (inputs.nixpkgs-unstable.sourceInfo) lastModified narHash rev;
      };
      # not using `input.self` here in order to avoid rebuilding every system on every update
      my.to = {
        type = "github";
        owner = "afsc19";
        repo = "nixos-config";
        ref = "refs/heads/main";
      };
    };

    nixPath = [
      "nixpkgs=flake:pkgs"
      "my=flake:my"
    ];
  };

  security.sudo.extraConfig = ''
    Defaults lecture=never
  '';

  # Every host shares the same time zone. (By default)
  time.timeZone = lib.mkDefault "Europe/Lisbon";

  #networking.domain = lib.mkDefault ".com";

  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';

  # Avoid running out of space on the boot partition
  boot.loader.grub.configurationLimit = lib.mkDefault 20;
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 20;

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # dedup equal pages
  hardware.ksm = {
    enable = true;
    sleep = null;
  };

  # move to personal?
  # --- Region/Locale ---
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "pt_PT.UTF-8/UTF-8" ];
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_PT.UTF-8";
    LC_IDENTIFICATION = "pt_PT.UTF-8";
    LC_MEASUREMENT = "pt_PT.UTF-8";
    LC_MONETARY = "pt_PT.UTF-8";
    LC_NAME = "pt_PT.UTF-8";
    LC_NUMERIC = "pt_PT.UTF-8";
    LC_PAPER = "pt_PT.UTF-8";
    LC_TELEPHONE = "pt_PT.UTF-8";
    LC_TIME = "pt_PT.UTF-8";
  };
}