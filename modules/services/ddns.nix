# Cloudflare dynamic DNS for world.<hostname>.andrecadete.com
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
    types
    ;
  cfg = config.modules.services.ddns;
  tokenFile = "/run/cloudflare-dyndns-token/token";
in
{
  options.modules.services.ddns = {
    enable = mkEnableOption "Cloudflare dynamic DNS";

    domains = mkOption {
      type = types.listOf types.str;
      default = [ "world.${config.networking.hostName}.andrecadete.com" ];
      description = "Records (DNS only, not proxied) pointing to this host's public addresses.";
    };

    ipv6 = mkOption {
      type = types.bool;
      default = true;
      description = "Also publish AAAA records.";
    };
  };

  config = mkIf cfg.enable {
    age.secrets.cloudflareDnsApiToken = {
      file = secrets.server.cloudflareDnsApiToken;
      owner = "acme";
      group = "acme";
      mode = "0400";
    };

    systemd.services.cloudflare-dyndns-token = {
      description = "Extract the Cloudflare API token for cloudflare-dyndns";
      before = [ "cloudflare-dyndns.service" ];
      requiredBy = [ "cloudflare-dyndns.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = "cloudflare-dyndns-token";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
      };
      script = ''
        sed -n 's/^[A-Z_]*TOKEN=//p' ${config.age.secrets.cloudflareDnsApiToken.path} | head -n 1 | tr -d '"\n' > ${tokenFile}
        test -s ${tokenFile}
      '';
    };

    services.cloudflare-dyndns = {
      enable = true;
      apiTokenFile = tokenFile;
      inherit (cfg) domains ipv6;
      proxied = false;
      frequency = "*:0/5"; # 5mins
    };
  };
}
