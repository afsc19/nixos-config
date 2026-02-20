# OneDrive rclone mount configuration.
{
  config,
  lib,
  pkgs,
  secrets,
  user,
  ...
}:
let
  cfg = config.modules.services.onedrive;
in
{
  options.modules.services.onedrive = {
    enable = lib.mkEnableOption "OneDrive rclone mount";
    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "OneDrive";
      description = "Directory where OneDrive will be mounted (relative to home).";
    };
    remoteName = lib.mkOption {
      type = lib.types.str;
      default = "onedrive";
      description = "Name of the remote in rclone.conf (e.g. 'onedrive').";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure rclone is installed
    environment.systemPackages = [ pkgs.rclone ];

    # Enable FUSE
    programs.fuse.userAllowOther = true;

    # Age secret for rclone config
    age.secrets.rclone = {
      file = secrets.personal.rclone;
      owner = user;
    };

    # systemd user service for mounting
    # This runs as the user, mounting into their home directory.
    hm.systemd.user.services.rclone-onedrive = {
      Unit = {
        Description = "rclone OneDrive mount";
        After = [ "network.target" ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service = {
        Type = "simple";
        # Force create mountpoint
        ExecStartPre = "/run/current-system/sw/bin/mkdir -p %h/${cfg.mountPoint}";
        
        # rclone mount command with optimizations for reliability and performance
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount ${cfg.remoteName}: %h/${cfg.mountPoint} \
            --config ${config.age.secrets.rclone.path} \
            --vfs-cache-mode full \
            --vfs-cache-max-size 10G \
            --vfs-cache-timeout 1h \
            --vfs-read-chunk-size 64M \
            --vfs-read-chunk-size-limit 1G \
            --dir-cache-time 1000h \
            --buffer-size 32M \
            --vfs-cache-poll-interval 1m \
            --attr-timeout 1s \
            --no-modtime \
            --links
        '';

        # Clean unmount on stop
        ExecStop = "/run/current-system/sw/bin/fusermount -u %h/${cfg.mountPoint}";
        
        # Restart logic
        Restart = "on-failure";
        RestartSec = "10s";
        
        # Prevent hanging the system on shutdown if mount is stuck
        TimeoutStopSec = "20s";
      };
    };
  };
}
