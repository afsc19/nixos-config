# zsh (with oh-my-zsh) configuration.
{
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

          naut = "nautilus . 2>/dev/null &";

          nixsh = "NIXPKGS_ALLOW_UNFREE=1 nix shell --impure";
          nixup = "(OLD_PATH=$PWD; trap \"cd $OLD_PATH; unset OLD_PATH\" EXIT; cd ~/nixos-config && git pull && sudo nixos-rebuild switch --flake ~/nixos-config#$(uname -n) --show-trace)";
          nixdev = "nix develop path:. -c zsh";

          docker = "sudo docker";
          suz = "sudo -E zsh";
          
        };

        # Disable beep when no file is found, per example.
        initContent = ''
          # unsetopt beep
          bindkey "^[[1;5C" forward-word # Ctrl + Right Arrow
          bindkey "^[[1;5D" backward-word # Ctrl + Left Arrow
          bindkey '^H' backward-kill-word # Ctrl + Backspace
          bindkey "^[[3;5~" kill-word # Ctrl + Delete

          initctfflake() {
            if [[ -f flake.nix ]] then
              echo "flake.nix already exists"
            else
              cat <<EOF > flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }: let 
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    pythonEnv = (python313.withPackages (ps: [ ps.numpy ps.matplotlib ]));
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        pythonEnv
      ];

      shellHook = \'\'
        ln -sfn \$\{pythonEnv\} .venv
      \'\';
    };
  };
}
EOF
              echo "flake.nix created"
            fi
          }
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
