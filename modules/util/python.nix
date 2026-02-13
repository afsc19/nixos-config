# KVM/libvirt configuration
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
    environment.systemPackages = with pkgs; [
      python3
    ];

    hm.programs.zsh.initExtra = ''
      penv() {
        if [[ -n "$VIRTUAL_ENV" ]]; then
          deactivate
        else
          [[ -d .venv ]] || python3 -m venv .venv
          source .venv/bin/activate
        fi
      }
    '';
  };
}
