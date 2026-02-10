# Bootloader options configuration
{ lib, ... }:
let
  inherit (lib) mkOption types mkDefault;
in
{
  options.my.bootloader = {
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
