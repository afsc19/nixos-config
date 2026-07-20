{
  ...
}:
{
  # --- Sound ---
  # sound.enable = true; # No longed needed
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    #isDefault
    #wireplumber.enable= true;

    # Auto-switch between speaker/headphone profiles on jack events
    wireplumber.extraConfig."10-alsa-autoswitch" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "device.name" = "~alsa_card.*"; }
          ];
          actions = {
            update-props = {
              "api.acp.auto-profile" = true;
            };
          };
        }
      ];
    };

    # bluetooth fixes
    wireplumber.extraConfig."20-bluez" = {
      "monitor.bluez.properties" = {
        "bluez5.enable-msbc" = true;
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-hw-volume" = true;
      };
    };

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    # media-session.enable = true;
  };
  modules.audio.easyeffects.enable = true;
}
