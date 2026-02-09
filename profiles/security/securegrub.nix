# Grub 2 configuration with fake secure boot (Only avoids secure boot violations)
{ lib, pkgs, config, ... }:
let
  plymouthTheme = "glitch";
in
{
  # Plymouth:
  boot.plymouth = {
    enable = true;
    theme = plymouthTheme;
    themePackages = with pkgs; [
      (adi1090x-plymouth-themes.override {
        selected_themes = [ plymouthTheme ];
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
    '';

    # Crucial for Plymouth: Pass the correct video mode from GRUB to the kernel
    gfxmodeEfi = "auto";
    gfxpayloadEfi = "keep";


    extraInstallCommands = ''
      set -e
      # Sign GRUB, Shim, and MM if keys exist
      if [ -f "${config.my.filesystem.pkiBundle}/keys/db/db.key" ]; then
        echo "[secureboot] Patching GRUB to ignore Secure Boot..."
        # Patch "SecureBoot" -> "SecureB00t" (Both UTF-16LE and ASCII)
        ${pkgs.perl}/bin/perl -0777 -pi -e 's/\x53\x00\x65\x00\x63\x00\x75\x00\x72\x00\x65\x00\x42\x00\x6F\x00\x6F\x00\x74/\x53\x00\x65\x00\x63\x00\x75\x00\x72\x00\x65\x00\x42\x00\x30\x00\x30\x00\x74/g' ${config.boot.loader.efi.efiSysMountPoint}/EFI/${config.my.filesystem.bootPartitionName}/grubx64.efi
        ${pkgs.perl}/bin/perl -0777 -pi -e 's/SecureBoot/SecureB00t/g' ${config.boot.loader.efi.efiSysMountPoint}/EFI/${config.my.filesystem.bootPartitionName}/grubx64.efi

        echo "[secureboot] Signing all EFI binaries in ${config.boot.loader.efi.efiSysMountPoint}..."
        # Remove explicitly patched grub from db first (to avoid digest errors)
        ${pkgs.sbctl}/bin/sbctl remove-file ${config.boot.loader.efi.efiSysMountPoint}/EFI/${config.my.filesystem.bootPartitionName}/grubx64.efi || true
        
        # Find and sign all .efi binaries and kernels
        ${pkgs.findutils}/bin/find ${config.boot.loader.efi.efiSysMountPoint} -type f \( -name "*.efi" -o -name "*bzImage" \) -exec ${pkgs.sbctl}/bin/sbctl sign -s {} \;
      else
        echo "[secureboot] keys missing; skipping signing."
      fi
    '';
  };

  environment.systemPackages = with pkgs; [
    sbctl
  ];

  # Re-sign GRUB on activation if needed
  system.activationScripts.secureboot-resign = lib.stringAfter [ "users" ] ''
    if [ -f "${config.my.filesystem.pkiBundle}/keys/db/db.key" ]; then
      if ${pkgs.sbctl}/bin/sbctl verify 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q grubx64.efi | ${pkgs.gnugrep}/bin/grep -q UNSIGNED; then
        echo "[secureboot] Activation: signing grubx64.efi"
        ${pkgs.sbctl}/bin/sbctl sign ${config.boot.loader.efi.efiSysMountPoint}/EFI/${config.my.filesystem.bootPartitionName}/grubx64.efi || echo "[secureboot] activation signing failed"
      fi
    fi
  '';
}
