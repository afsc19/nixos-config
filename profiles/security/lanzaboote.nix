# Systemd-boot with secure boot using lanzaboote
{ pkgs, config, ... }:
{

  boot.loader.systemd-boot.enable = false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = config.my.bootloader.pkiBundle;
  };

  # Always keep this for checks
  environment.systemPackages = with pkgs; [
    sbctl
  ];
}
