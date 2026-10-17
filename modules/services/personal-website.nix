# personal website + cv, served static by nginx
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modules.services.personal-website;
in
{
  options.modules.services.personal-website = {
    enable = mkEnableOption "personal website and cv static vhosts";

    acmeHost = mkOption {
      type = types.str;
      default = "andrecadete.com";
      description = "Name of the provisioned ACME certificate to use.";
    };

    websiteRoot = mkOption {
      type = types.path;
      default = "/srv/www/afsc-website";
      description = "Static root of the personal website.";
    };

    cvRoot = mkOption {
      type = types.path;
      default = "/srv/www/cv";
      description = "Static root of the cv and other documents.";
    };
  };

  config = mkIf cfg.enable {
    services.nginx.virtualHosts = {
      "andrecadete.com" = {
        useACMEHost = cfg.acmeHost;
        forceSSL = true;
        http2 = true;
        locations."/".root = cfg.websiteRoot;
      };

      "cv.andrecadete.com" = {
        useACMEHost = cfg.acmeHost;
        forceSSL = true;
        http2 = true;
        locations."/" = {
          root = cfg.cvRoot;
          index = "cv.pdf";
          extraConfig = "autoindex on;";
        };
      };
    };
  };
}
