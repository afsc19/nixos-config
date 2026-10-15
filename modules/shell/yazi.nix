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
    mkDefault
    ;
  cfg = config.modules.shell.yazi;

  # Required dependency bundle
  requiredDeps = with pkgs; [
    unstable.yazi
    file
  ];

  # Recommended dependency bundle
  recommendedDeps = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    ffmpeg
    _7zz
    jq
    (lib.hiPrio poppler-utils)
    fd
    ripgrep
    fzf
    zoxide
    resvg
    imagemagick
    wl-clipboard
  ];

  # `y` helper: cd into yazi's last directory on exit (bash & zsh)
  yFunction = ''
    y() {
      local tmp cwd
      tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
      command yazi "$@" --cwd-file="$tmp"
      if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
      fi
      command rm -f -- "$tmp"
    }
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
    # System-wide so every user can run it
    environment.systemPackages = requiredDeps
      ++ lib.optionals cfg.installDependencies recommendedDeps
      ++ cfg.extraPackages;

    programs.bash.interactiveShellInit = yFunction;
    programs.zsh.interactiveShellInit = yFunction;

    hm.programs.yazi = {
      enable = true;
      package = pkgs.unstable.yazi;
      enableZshIntegration = mkDefault false;
      enableBashIntegration = mkDefault false;
    };
  };
}
