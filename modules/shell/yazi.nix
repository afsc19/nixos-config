# Yazi
{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.modules.shell.yazi;

  # Recommended dependency bundle
  recommendedDeps = with pkgs; [
    yazi
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    fd
    ripgrep
    fzf
    zoxide
    poppler-utils
    ffmpeg
    mediainfo
    chafa
    ueberzugpp
    exiftool
  ];

  # POSIX shell version of the `y` helper
  yFunctionPOSIX = ''
    y() {
      local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
      yazi "$@" --cwd-file="$tmp"
      if [ -f "$tmp" ]; then
        local cwd
        cwd="$(cat "$tmp")"
        if [ -n "$cwd" ] && [ -d "$cwd" ]; then
          cd "$cwd" || return
        fi
      fi
      rm -f "$tmp"
    }
  '';

  # fish shell variant
  yFunctionFish = ''
    function y
      set -l tmp (mktemp -t yazi-cwd.XXXXXX)
      yazi $argv --cwd-file=$tmp
      set -l cwd (cat $tmp)
      if test -n "$cwd" -a -d "$cwd"
        cd "$cwd"
      end
      rm -f $tmp
    end
  '';
in
{
  options.modules.shell.yazi = {
    enable = mkEnableOption "Yazi";
    installDependencies = mkOption {
      type = types.bool;
      default = true;
      description = "Install recommended dependencies along with yazi.";
    };
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional packages to install alongside yazi (system-wide & HM).";
    };
  };

  config = mkIf cfg.enable {
    hm = {
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        shellWrapperName = "y";
      };

      # Inject 'y'
      # programs.zsh.initContent = lib.mkAfter yFunctionPOSIX;
      # programs.bash.initExtra = lib.mkAfter yFunctionPOSIX;
      # programs.fish.interactiveShellInit = lib.mkAfter yFunctionFish;

      # Ensure packages exist for user profile
      home.packages = lib.mkIf cfg.installDependencies (recommendedDeps ++ cfg.extraPackages);
    };

    # System-wide yazi
    environment.systemPackages = lib.mkIf cfg.installDependencies (
      recommendedDeps ++ cfg.extraPackages
    );

    # Provide the function for non-HM managed POSIX shells (e.g. root, other users)
    environment.etc."profile.d/30-yazi-cwd.sh".text = yFunctionPOSIX;
  };
}
