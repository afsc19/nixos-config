# Distrobox configuration + arch and kali pods installed automatically (as a oneshot service) (for laptop devices)
{
  pkgs,
  config,
  lib,
  configDir,
  user,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.virtualization.distrobox;
in
{
  options.modules.virtualization.distrobox.enable = mkEnableOption "distrobox";

  config = mkIf cfg.enable {
    virtualisation.podman.enable = true;
    environment.systemPackages = (with pkgs; [
      distrobox
      podman
    ])
    # Optional but useful so user services are reliably started
    # TODO what is this
    systemd.user.startServices = "sd-switch";

    # TODO test first, how to ensure it will use podman instead of docker
    # systemd.user.services."distrobox-arch" = {
    #   description = "Ensure distrobox 'arch' exists";
    #   wantedBy = [ "default.target" ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #   };
    #   script = ''
    #     set -euo pipefail
    #     ${pkgs.distrobox}/bin/distrobox-create --name arch --image docker.io/library/archlinux:latest --yes || true
    #   '';
    # };

    # systemd.user.services."distrobox-kali" = {
    #   description = "Ensure distrobox 'kali' exists";
    #   wantedBy = [ "default.target" ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #   };
    #   script = ''
    #     set -euo pipefail
    #     ${pkgs.distrobox}/bin/distrobox-create --name kali --image docker.io/kalilinux/kali-rolling --yes || true
    #   '';
    # };
  }
}