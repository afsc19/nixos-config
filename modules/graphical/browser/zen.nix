# Spotify configuration and themeing with Spicetify
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.browser.zen;
in
{

  options.modules.graphical.browser.zen.enable = mkEnableOption "Zen Browser";

  config = mkIf cfg.enable {
    hm.sharedModules = [
      inputs.zen-browser.homeManagerModules.default;
    ];


    hm.programs.zen-browser = {
      enable = true;
      policies = let 
        mkExtensionSettings = builtins.mapAttrs (_: pluginId: {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
          installation_mode = "force_installed";
        });
      in {
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

      # Add any other native connectors here
      nativeMessagingHosts = [pkgs.firefoxpwa];
    };



    xdg.mimeApps = let
      value = let
        zen-browser = inputs.zen-browser.packages.${system}.beta; # or twilight
      in
        zen-browser.meta.desktopFileName;

      associations = builtins.listToAttrs (map (name: {
          inherit name value;
        }) [
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
        ]);
    in {
      associations.added = associations;
      defaultApplications = associations;
    };
  }

}