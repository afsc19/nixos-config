# Simple minecraft backups
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  cfg = config.modules.services.minecraftBackup;
in
{
  options.modules.services.minecraftBackup = {
    enable = lib.mkEnableOption "Sync Minepanel local restic backups to cloud via rclone";

    sourceBase = lib.mkOption {
      type = lib.types.str;
      default = "/home/afsc/Minecraft/minepanel/servers";
      description = "Directory containing one sub-directory per Minecraft server. Each server's restic repo is expected at <sourceBase>/<server>/backups/restic.";
    };

    remoteName = lib.mkOption {
      type = lib.types.str;
      default = "onedrive";
      description = "Name of the rclone remote (must be defined in the rclone config secret).";
    };

    remotePath = lib.mkOption {
      type = lib.types.str;
      default = "Documents/AFSC Home Lab/sylva/backups";
      description = "Destination path on the rclone remote, example: 'Documents/AFSC Home Lab/sylva/backups'.";
    };

    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 03:00:00";
      description = "systemd OnCalendar expression for the sync timer.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rclone ];

    age.secrets.minecraftBackupRclone = {
      file = secrets.sylva.rclone;
      owner = "root";
      mode = "600";
    };

    systemd.services.minecraft-backup-to-onedrive = {
      description = "Sync Minepanel restic backups to OneDrive";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.coreutils ];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        set -e
        for world in "${cfg.sourceBase}"/*; do
          restic_dir="$world/backups/restic"
          [ -d "$restic_dir" ] || continue
          name=$(basename "$world")
          echo "Syncing $restic_dir -> ${cfg.remoteName}:${cfg.remotePath}/$name/restic"
          ${pkgs.rclone}/bin/rclone sync \
            --config ${config.age.secrets.minecraftBackupRclone.path} \
            --fast-list \
            --stats-one-line \
            "$restic_dir" \
            "${cfg.remoteName}:${cfg.remotePath}/$name/restic"
        done
      '';
    };

    systemd.timers.minecraft-backup-to-onedrive = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
        RandomizedDelaySec = "15min";
      };
    };
  };
}
