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
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.modules.virtualization.distrobox;
in
{
  options.modules.virtualization.distrobox = {
    enable = mkEnableOption "distrobox";
    defaultBoxes = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Name of the distrobox container";
            };
            image = mkOption {
              type = types.str;
              description = "Image to use for the distrobox container";
            };
          };
        }
      );
      default = [ ];
      description = "List of distroboxes to create automatically";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.podman.enable = true;
    environment.systemPackages = (with pkgs; [
      distrobox
      podman
    ]);
    # Optional but useful so user services are reliably started
    hm.systemd.user.startServices = true;

    systemd.user.services =
      let
        mkDistroboxService = box: {
          name = "distrobox-${box.name}";
          value = {
            description = "Ensure distrobox '${box.name}' exists";
            wantedBy = [ "default.target" ];
            serviceConfig = {
              Type = "oneshot";
            };
            script = ''
              set -euo pipefail
              ${pkgs.distrobox}/bin/distrobox-create --name ${box.name} --image ${box.image} --yes || true
            '';
          };
        };
      in
      lib.listToAttrs (map mkDistroboxService cfg.defaultBoxes);
  };
}