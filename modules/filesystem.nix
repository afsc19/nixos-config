# Network configuration, from diogotcorreia
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.filesystem = {
    bootPartitionName = mkOption {
      type = types.str;
      default = "NixOS-boot";
      description = "The folder to which grub is usually deployed, in /boot/EFI/";
    };
    secureBootKeysDir = mkOption {
      type = types.str;
      default = "/var/lib/sbctl/keys"; # sbctl default; created automatically by sbctl create-keys
      description = "The folder that contains the secure boot MOK keys.";
    };
  };
}
