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
          # Switches
          #switchhypr = "sudo nixos-rebuild switch --flake .#hyprland";
          #switchuhypr = "sudo nixos-rebuild switch --upgrade --flake .#hyprland";
          switchgnome = "sudo nixos-rebuild switch --flake .#gnome";
          switchugnome = "sudo nixos-rebuild switch --upgrade --flake .#gnome";


          clean = "sudo nix-collect-garbage -d";
          cleanold = "sudo nix-collect-garbage --delete-old";
          cleanboot = "sudo /run/current-system/bin/switch-to-configuration boot";

          # TODO should I wrap my nvim?
          #nvim="kitty @ set-spacing padding=0 && /etc/profiles/per-user/nomad/bin/nvim";

          # TODO create and move to kubernetes module
          k = "kubectl";

          # TODO create and move to cybersec module
          urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
          urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";

          

        };

        # Disable beep when no file is found, per example.
        #initExtra = "unsetopt beep";

        enableAutosuggestions = true;
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

    };

    # Enable zsh outside home?
    programs.zsh.enable = true;
  };
}