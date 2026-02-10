# Bootloader options configuration
{ lib, ... }:
let
  inherit (lib) mkOption types mkDefault;
in
{
  options.my.bootloader = {
    bootPartitionName = mkOption {
      type = types.str;
      default = "NixOS-boot";
      description = "The folder to which grub is usually deployed, in /boot/EFI/";
    };
    pkiBundle = mkOption {
      type = types.str;
      default = "/var/lib/sbctl"; # sbctl default; created automatically by sbctl create-keys
      description = "The folder that contains the secure boot MOK keys.";
    };
  };

  # Required for "reboot --firmware-setup"
  config.boot.loader.efi.canTouchEfiVariables = mkDefault true;

  # Already default
  # boot.loader.timeout = mkDefault 5;
}
