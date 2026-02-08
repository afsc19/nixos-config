# Grub 2 configuration with secure boot (only for the latest config, secure boot must be disabled to boot older configs)
{ lib, pkgs, config, ... }:
let
  secureBootDir = "/var/lib/sbctl/keys"; # sbctl default; created automatically by sbctl create-keys
  secureBootEfiFolderName = "NixOS-boot"; # TODO make this a config option
  plymouthTheme = "glitch";

  # --- Versioned signed-kernel logic ---
  espMount = config.boot.loader.efi.efiSysMountPoint or "/boot";

  # Short unique ID derived from kernel/initrd (avoids infinite recursion with toplevel)
  buildId = builtins.substring 0 7 (builtins.hashString "sha256" (toString config.boot.kernelPackages.kernel + toString config.system.build.initialRamdisk));

  # Versioned names
  kernelName = "vmlinuz-${config.system.nixos.label}-${buildId}";
  initrdName = "initrd-${config.system.nixos.label}-${buildId}";

  destDir    = "${espMount}/EFI/nixos-signed";
  kernelDest = "${destDir}/${kernelName}";
  initrdDest = "${destDir}/${initrdName}";

  copyAndSignScript = pkgs.writeShellScript "secure-boot-versioned" ''
    set -e

    # Only run if sbctl keys exist
    if [ ! -f "${secureBootDir}/db/db.key" ] && [ ! -f "${secureBootDir}/db.key" ]; then
      echo "[secureboot] No sbctl keys yet; skipping kernel signing."
      exit 0
    fi

    mkdir -p "${destDir}"

    # 1. Copy & sign kernel if missing
    if [ ! -f "${kernelDest}" ]; then
      echo "[secureboot] Installing & Signing Kernel: ${kernelName}"
      cp "${config.boot.kernelPackages.kernel}/bzImage" "${kernelDest}"
      ${pkgs.sbctl}/bin/sbctl sign -s "${kernelDest}" || echo "[secureboot] kernel signing failed"
    fi

    # 2. Copy initrd (unsigned, because it's a CPIO archive, not a PE binary)
    if [ ! -f "${initrdDest}" ]; then
      echo "[secureboot] Installing Initrd: ${initrdName}"
      cp "${config.system.build.initialRamdisk}/initrd" "${initrdDest}"
    fi

    # TODO cleanup old versions
  '';
in
{
  # Plymouth:
  boot.plymouth = {
    enable = true;
    theme = plymouthTheme;
    themePackages = with pkgs; [
      (adi1090x-plymouth-themes.override {
        selected_themes = [ plymouthTheme ]; # Only install the selected theme
      })
    ];
  };

  # Enable systemd in initrd. This is required for the modern graphical 
  # LUKS unlock prompt to integrate correctly with Plymouth.
  boot.initrd.systemd.enable = true;

  # Allow Plymouth to show the animation
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
  ];
  boot.consoleLogLevel = 0;

  boot.loader.efi.canTouchEfiVariables = true; # Required for "reboot --firmware-setup"
  boot.loader.timeout = 200;

  # Use sbctl verify, sbctl status, to check if it's working.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
    default = "saved";

    dedsec-theme = {
      enable = true;
      style = "firewall";
      icon = "white";
      resolution = "1440p";
    };

    extraEntries = ''
      menuentry "UEFI Firmware Settings" {
        fwsetup
      }

      # Signed-current-generation entry
      menuentry "NixOS (current, signed kernel)" {
        search --file --no-floppy --set=esp /EFI/nixos-signed/${kernelName}
        set root=($esp)
        linux /EFI/nixos-signed/${kernelName} init=${config.system.build.bootStage2} ${toString config.boot.kernelParams}
        initrd /EFI/nixos-signed/${initrdName}
      }
    '';

    # Crucial for Plymouth: Pass the correct video mode from GRUB to the kernel
    gfxmodeEfi = "auto";
    gfxpayloadEfi = "keep";

    extraFiles = {
      "EFI/${secureBootEfiFolderName}/shimx64.efi" = "${pkgs.shim-unsigned}/share/shim/shimx64.efi";
      "EFI/${secureBootEfiFolderName}/mmx64.efi"   = "${pkgs.shim-unsigned}/share/shim/mmx64.efi";
    };

    # Post-install hook: first-time key generation + MOK enrollment + signing (idempotent)
    extraInstallCommands = ''
      set -e
      # First install detection: absence of db.key triggers key creation & mok enrollment
      if [ ! -f "${secureBootDir}/db/db.key" ] && [ ! -f "${secureBootDir}/db.key" ]; then
        echo "[secureboot] No Secure Boot keys detected. Creating and enrolling MOK..."
        ${pkgs.sbctl}/bin/sbctl create-keys
        # Automatic MOK enrollment scheduling (user still confirms at next boot screen)
        if ${pkgs.sbctl}/bin/sbctl enroll-keys -m -t; then
          echo "[secureboot] Key enrollment scheduled. Reboot and accept the MOK manager prompt if needed."
        else
          echo "[secureboot] Failed to schedule key enrollment; ensure you are in Setup Mode or run 'sbctl enroll-keys --microsoft' manually."
        fi
      else
        echo "[secureboot] Secure Boot keys already present; skipping creation & enrollment schedule."
      fi

      # Attempt to sign grub + shim + mm if keys exist
      if [ -f "${secureBootDir}/db/db.key" ] || [ -f "${secureBootDir}/db.key" ]; then
        echo "[secureboot] Signing GRUB and shim binaries"
        ${pkgs.sbctl}/bin/sbctl sign ${config.boot.loader.efi.efiSysMountPoint}/EFI/${secureBootEfiFolderName}/grubx64.efi || true
        ${pkgs.sbctl}/bin/sbctl sign ${config.boot.loader.efi.efiSysMountPoint}/EFI/${secureBootEfiFolderName}/mmx64.efi   || true
        ${pkgs.sbctl}/bin/sbctl sign ${config.boot.loader.efi.efiSysMountPoint}/EFI/${secureBootEfiFolderName}/shimx64.efi || true
      else
        echo "[secureboot] grub/shim unsigned but keys missing; will sign after keys exist."
      fi
    '';
  };

  environment.systemPackages = with pkgs; [
    sbctl
    shim-unsigned
  ];

  # Activation script: re-check & (re)sign GRUB after switch
  system.activationScripts.secureboot-resign = lib.stringAfter [ "users" ] ''
    if [ -f "${secureBootDir}/db/db.key" ] || [ -f "${secureBootDir}/db.key" ]; then
      if ${pkgs.sbctl}/bin/sbctl verify 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q grubx64.efi | ${pkgs.gnugrep}/bin/grep -q UNSIGNED; then
        echo "[secureboot] Activation: signing grubx64.efi"
        ${pkgs.sbctl}/bin/sbctl sign ${config.boot.loader.efi.efiSysMountPoint}/EFI/${secureBootEfiFolderName}/grubx64.efi || echo "[secureboot] activation signing failed"
      fi
    fi
  '';

  # Activation script: copy & sign versioned kernel/initrd
  system.activationScripts.secureBootSignVersioned = lib.stringAfter [ "secureboot-resign" ] "${copyAndSignScript}";
}
