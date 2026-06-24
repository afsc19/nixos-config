# Cloudflare Tunnel (cloudflared) Configuration
{
  config,
  lib,
  secrets,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    listToAttrs
    types
    ;
  cfg = config.modules.services.cloudflared;
in
{
  options.modules.services.cloudflared = {
    enable = mkEnableOption "Cloudflared (Cloudflare Tunnel)";
    tunnels = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            tunnelName = mkOption {
              type = types.str;
              description = "The Name of the tunnel.";
            };

            tunnelID = mkOption {
              type = types.str;
              description = "The ID of the tunnel.";
            };

            default = mkOption {
              type = types.str;
              default = "https://localhost:443";
              description = "Default tunnel routing target.";
            };
          };
        }
      );
      default = [ ];
      description = "The tunnels to activate.";
    };
  };

  config = mkIf cfg.enable {
    users.users.cloudflared = {
      isSystemUser = true;
      group = "cloudflared";
    };
    users.groups.cloudflared = { };

    age.secrets = listToAttrs (
      map (entry: {
        name = "cloudflaredTunnel_${entry.tunnelName}";
        value = {
          file = secrets.host."cloudflaredTunnel_${entry.tunnelName}";
          owner = "cloudflared";
        };
      }) cfg.tunnels
    );

    services.cloudflared = {
      enable = true;
      tunnels = listToAttrs (
        map (entry: {
          name = entry.tunnelID;
          value = {
            credentialsFile = config.age.secrets."cloudflaredTunnel_${entry.tunnelName}".path;
            default = entry.default;
            originRequest = {
              noTLSVerify = true;
            };
          };
        }) cfg.tunnels
      );
    };
  };
}
