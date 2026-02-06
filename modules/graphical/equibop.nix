# Discord configuration
{
  config,
  lib,
  unstable,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.equibop;
in
{
  options.modules.graphical.equibop.enable = mkEnableOption "Equibop Discord";

  config = mkIf cfg.enable {
    # Unstable fixes the icon
    hm.home.packages = with unstable; [
      equibop
    ];
  };
}
