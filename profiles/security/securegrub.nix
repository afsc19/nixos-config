{ lib, pkgs, ... }:
let
  secureBootDir = "/var/lib/sbctl/keys"; # sbctl default; created automatically by sbctl create-keys
  plymouthTheme = "target_2";
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

    extraEntries = ''
      menuentry "UEFI Firmware Settings" {
        fwsetup
      }
    '';

    # Crucial for Plymouth: Pass the correct video mode from GRUB to the kernel
    gfxmodeEfi = "auto";
    gfxpayloadEfi = "keep";

    extraFiles = {
      "shimx64.efi" = "${pkgs.shim-unsigned}/share/shim/shimx64.efi";
      "mmx64.efi" = "${pkgs.shim-unsigned}/share/shim/mmx64.efi";
    };
    # Post-install hook: first-time key generation + MOK enrollment + signing (idempotent)
    extraInstallCommands = ''
      set -e
      # First install detection: absence of db.key triggers key creation & mok enrollment
      if [ ! -f "${secureBootDir}/db.key" ]; then
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

      # Attempt to sign grub if unsigned and keys exist (will fail gracefully if not enrolled yet)
      if ${pkgs.sbctl}/bin/sbctl verify 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q grubx64.efi | ${pkgs.gnugrep}/bin/grep -q UNSIGNED; then
        if [ -f "${secureBootDir}/db.key" ]; then
          echo "[secureboot] Signing grubx64.efi"
          ${pkgs.sbctl}/bin/sbctl sign /boot/efi/EFI/nixos/grubx64.efi || echo "[secureboot] grub signing failed (expected if keys not yet trusted)."
        else
          echo "[secureboot] grub unsigned but keys missing; will sign after keys exist."
        fi
      fi
    '';
  };

  environment.systemPackages = with pkgs; [
    sbctl
    shim-unsigned
  ];

  # Activation script: re-check & (re)sign after switch (covers grub path changes)
  system.activationScripts.secureboot-resign = lib.stringAfter [ "users" ] ''
    if [ -f "${secureBootDir}/db.key" ]; then
      if ${pkgs.sbctl}/bin/sbctl verify 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q grubx64.efi | ${pkgs.gnugrep}/bin/grep -q UNSIGNED; then
        echo "[secureboot] Activation: signing grubx64.efi"
        ${pkgs.sbctl}/bin/sbctl sign /boot/efi/EFI/nixos/grubx64.efi || echo "[secureboot] activation signing failed"
      fi
    fi
  '';
}
