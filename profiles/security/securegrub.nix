{ lib, pkgs, ... }:
let
  secureBootDir = "/var/lib/sbctl/keys"; # sbctl default; created automatically by sbctl create-keys
in
{

  # Use sbctl verify, sbctl status, to check if it's working.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
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
        if ${pkgs.sbctl}/bin/sbctl enroll-mok; then
          echo "[secureboot] MOK enrollment scheduled. Reboot and accept the MOK manager prompt."
        else
          echo "[secureboot] Failed to schedule MOK enrollment; run 'sbctl enroll-mok' manually."
        fi
      else
        echo "[secureboot] Secure Boot keys already present; skipping creation & enrollment schedule."
      fi

      # Attempt to sign grub if unsigned and keys exist (will fail gracefully if not enrolled yet)
      if ${pkgs.sbctl}/bin/sbctl verify 2>/dev/null | grep -q grubx64.efi | grep -q UNSIGNED; then
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
      if ${pkgs.sbctl}/bin/sbctl verify 2>/dev/null | grep -q grubx64.efi | grep -q UNSIGNED; then
        echo "[secureboot] Activation: signing grubx64.efi"
        ${pkgs.sbctl}/bin/sbctl sign /boot/efi/EFI/nixos/grubx64.efi || echo "[secureboot] activation signing failed"
      fi
    fi
  '';
}
