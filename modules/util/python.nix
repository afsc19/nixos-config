# Python
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.util.python;
in
{
  options.modules.util.python.enable = mkEnableOption "Python3";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs.unstable; [
      python3
    ];

    hm.programs.zsh.initContent = ''
      penv() {
        if [[ -n "$VIRTUAL_ENV" ]]; then
          if typeset -f deactivate >/dev/null 2>&1; then
            deactivate
          else
            source "$VIRTUAL_ENV/bin/activate" 2>/dev/null && deactivate || {
              PATH="''${PATH/#$VIRTUAL_ENV\/bin:/}"
              unset VIRTUAL_ENV
              hash -r
            }
          fi
        else
          [[ -d .venv ]] || python3 -m venv .venv
          source .venv/bin/activate
        fi
      }
    '';
  };
}
