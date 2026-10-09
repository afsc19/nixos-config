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
  pythonPkg = pkgs.python3;
  pythonld = pkgs.writeShellScriptBin "pythonld" ''
    export LD_LIBRARY_PATH="''${NIX_LD_LIBRARY_PATH:-/run/current-system/sw/share/nix-ld/lib}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec -a "$0" ${pythonPkg}/bin/python3 "$@"
  '';
in
{
  options.modules.util.python.enable = mkEnableOption "Python3";

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pythonPkg
      pythonld
    ];

    hm.programs.zsh.initContent = ''
      _penv_push_ld() {
        if [[ -z "''${_PENV_OLD_LD_SET:-}" ]]; then
          if [[ -z "''${LD_LIBRARY_PATH+x}" ]]; then
            _PENV_OLD_LD_LIBRARY_PATH=""
            _PENV_OLD_LD_SET="unset"
          else
            _PENV_OLD_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
            _PENV_OLD_LD_SET="set"
          fi
        fi
        if [[ -n "''${NIX_LD_LIBRARY_PATH:-}" ]]; then
          if [[ -n "''${LD_LIBRARY_PATH:-}" ]]; then
            case ":$LD_LIBRARY_PATH:" in
              *":$NIX_LD_LIBRARY_PATH:"*) ;;
              *) export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH:$LD_LIBRARY_PATH" ;;
            esac
          else
            export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH"
          fi
        fi
      }
      _penv_pop_ld() {
        if [[ "''${_PENV_OLD_LD_SET:-}" == "unset" ]]; then
          unset LD_LIBRARY_PATH
        elif [[ "''${_PENV_OLD_LD_SET:-}" == "set" ]]; then
          export LD_LIBRARY_PATH="$_PENV_OLD_LD_LIBRARY_PATH"
        fi
        unset _PENV_OLD_LD_LIBRARY_PATH _PENV_OLD_LD_SET
      }
      _penv_deactivate() {
        if typeset -f deactivate >/dev/null 2>&1; then
          deactivate
        else
          source "$VIRTUAL_ENV/bin/activate" 2>/dev/null && deactivate || {
            PATH="''${PATH/#$VIRTUAL_ENV\/bin:/}"
            unset VIRTUAL_ENV
            hash -r
          }
        fi
        _penv_pop_ld
        hash -r
      }
      penv() {
        if [[ -n "$VIRTUAL_ENV" ]]; then
          _penv_deactivate
        else
          [[ -d .venv ]] || pythonld -m venv .venv
          _penv_push_ld
          source .venv/bin/activate
        fi
      }
      penvd() {
        if [[ -n "$VIRTUAL_ENV" ]]; then
          _PENV_DEL_TARGET="$VIRTUAL_ENV"
          _penv_deactivate
          rm -rf "$_PENV_DEL_TARGET"
          unset _PENV_DEL_TARGET
        else
          rm -rf .venv
        fi
      }
    '';
  };
}
