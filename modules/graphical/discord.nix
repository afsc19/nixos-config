# Discord configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.discord;

  settings = {
    openasar = {
      setup = true;
      cmdPreset = if config.my.hardware.laptop then "battery" else "perf";
      quickstart = true;
    };
    DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
    SKIP_HOST_UPDATE = true;
    MINIMIZE_TO_TRAY = false;
    OPEN_ON_STARTUP = false;
  };

  settingsFile =
    pkgs.runCommand "settings-override.json"
      {
        nativeBuildInputs = with pkgs; [ jq ];
      }
      ''
        jq --argjson cfg ${lib.escapeShellArg (builtins.toJSON settings)} \
          '$cfg * (.openasar.css = $css + "\n" + $extraCss)' -n > $out
      '';
in
{
  options.modules.graphical.discord.enable = mkEnableOption "Discord (openasar)";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      # Discord
      discord-openasar
    ];

    # Discord configuration
    hm.xdg.configFile."discord/settings-override.json".source = settingsFile;
  };
}