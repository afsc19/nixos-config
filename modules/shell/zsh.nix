# zsh (with oh-my-zsh) configuration.
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.shell.zsh;
in
{
  options.modules.shell.zsh.enable = mkEnableOption "zsh";

  # Home manager module
  config = mkIf cfg.enable {
    hm = {
      programs.zsh = {
        enable = true;
    
        shellAliases = {
          clean = "sudo nix-collect-garbage -d";
          cleanold = "sudo nix-collect-garbage --delete-old";
          cleanboot = "sudo /run/current-system/bin/switch-to-configuration boot";

          # TODO create and move to cybersec module
          urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
          urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";

          naut = "nautilus . 2>/dev/null &";
        };

        # Disable beep when no file is found, per example.
        initContent = ''
          # unsetopt beep
          bindkey "^[[1;5C" forward-word # Ctrl + Right Arrow
          bindkey "^[[1;5D" backward-word # Ctrl + Left Arrow
          bindkey '^H' backward-kill-word # Ctrl + Backspace
          bindkey "^[[3;5~" kill-word # Ctrl + Delete
        '';

        autosuggestion.enable = true;
        zplug = {
          enable = true;
          plugins = [
            { name = "zsh-users/zsh-autosuggestions"; }
            { name = "zsh-users/zsh-syntax-highlighting"; }	
          ];
        };
      };

      # Enable starship (shell theme)
      programs.starship = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };

    };

    # Enable zsh outside home?
    programs.zsh.enable = true;
  };
}