# Zen browser + extensions configuration
{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.browser.zen;

  zenPackage = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta;
in
{

  options.modules.graphical.browser.zen.enable = mkEnableOption "Zen Browser";

  config = mkIf cfg.enable {
    home-manager.sharedModules = [
      inputs.zen-browser.homeModules.default
    ];

    hm.programs.zen-browser = {
      enable = true;
      package = zenPackage;
      # suppressXdgMigrationWarning = true;
      policies =
        let
          mkExtensionSettings = builtins.mapAttrs (
            _: pluginId: {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
              installation_mode = "force_installed";
            }
          );
        in
        {
          # Extensions, ignored when signed in.
          ExtensionSettings = mkExtensionSettings {
            # "extension-ID" = "extension-name";
            "f5176f96-c171-4551-9c29-724858fd5e8b" = "ublock-origin";
            "e58d3966-3d76-4cd9-8552-1582fbc800c1" = "buster-captcha-solver";
            "aecec67f-0d10-4fa7-b7c7-609a2db280cf" = "violentmonkey";
          };

          # Settings
          #AutofillAddressEnabled = true;
          #AutofillCreditCardEnabled = false;
          #DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          #DontCheckDefaultBrowser = true;
          #NoDefaultBookmarks = true;
          OfferToSaveLogins = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
        };

      profiles."Default Profile" = {
        id = 0;
        isDefault = true;
        path = "otvn57o5.Default Profile";

        spaces =
          let
            mkSpace =
              {
                id,
                position,
                rgb,
                lightness,
                opacity,
                x,
                y,
                type ? "undefined",
                pins ? { },
              }:
              {
                inherit id position pins;
                theme = {
                  inherit opacity;
                  type = "gradient";
                  texture = 0.0;
                  colors = [
                    {
                      red = builtins.elemAt rgb 0;
                      green = builtins.elemAt rgb 1;
                      blue = builtins.elemAt rgb 2;
                      inherit lightness type;
                      position = { inherit x y; };
                    }
                  ];
                };
              };
          in
          {
            "Space" = mkSpace {
              id = "7d45adaa-5749-4490-acbe-be49601e98eb";
              position = 100;
              rgb = [
                80
                223
                226
              ];
              lightness = 60;
              opacity = 0.25;
              x = 124;
              y = 179;
              type = "explicit-lightness";
            };
            "IST" = mkSpace {
              id = "6dde22e2-ec9f-4e50-83ec-47bad917d858";
              position = 200;
              rgb = [
                6
                77
                228
              ];
              lightness = 46;
              opacity = 0.492;
              x = 113;
              y = 121;
            };
            "STT" = mkSpace {
              id = "4a3c239e-4d72-4ed2-9a9d-79f3c8e9f039";
              position = 300;
              rgb = [
                6
                53
                178
              ];
              lightness = 36;
              opacity = 0.25;
              x = 130;
              y = 132;
            };
            "home lab" = mkSpace {
              id = "193416ce-4716-4f4a-a7f9-fd09bf67be96";
              position = 400;
              rgb = [
                54
                22
                2
              ];
              lightness = 11;
              opacity = 0.57;
              x = 200;
              y = 188;
            };
          };
      };

      # Add any other native connectors here
      nativeMessagingHosts = [ pkgs.firefoxpwa ];
    };

    hm.xdg.mimeApps =
      let
        value = "zen-beta.desktop";

        associations = builtins.listToAttrs (
          map
            (name: {
              inherit name value;
            })
            [
              "application/x-extension-shtml"
              "application/x-extension-xhtml"
              "application/x-extension-html"
              "application/x-extension-xht"
              "application/x-extension-htm"
              #"x-scheme-handler/unknown"
              #"x-scheme-handler/mailto"
              "x-scheme-handler/chrome"
              "x-scheme-handler/about"
              "x-scheme-handler/https"
              "x-scheme-handler/http"
              "application/xhtml+xml"
              #"application/json"
              #"text/plain"
              "text/html"
              # PDF
              "application/pdf"
              # Images
              "image/avif"
              "image/bmp"
              "image/gif"
              "image/jpeg"
              "image/png"
              "image/svg+xml"
              "image/tiff"
              "image/vnd.microsoft.icon"
              "image/webp"
            ]
        );
      in
      {
        enable = true;
        associations.added = associations;
        defaultApplications = associations;
      };
  };

}
