# custom script to disable xhci wake when suspended so usb devices dont wake the pc up
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.laptop.lid-wakeups;

  manageXhciWake = pkgs.writeShellScript "manage-xhci-wake.sh" ''
    phase=$1
    STATE_FILE="/run/manage-xhci-wakeup-state"
    XHCI_PATH="/sys/bus/pci/devices/0000:00:14.0/power/wakeup"
    case "$phase" in
      pre)
        if [ -f "$XHCI_PATH" ]; then
          cat "$XHCI_PATH" > "$STATE_FILE" 2>/dev/null
          echo "disabled" > "$XHCI_PATH" 2>/dev/null || true
        fi
        ;;
      post)
        if [ -f "$STATE_FILE" ] && [ -f "$XHCI_PATH" ]; then
          cat "$STATE_FILE" > "$XHCI_PATH" 2>/dev/null || true
          rm -f "$STATE_FILE"
        fi
        ;;
    esac
  '';
in
{
  options.modules.laptop.lid-wakeups.enable =
    mkEnableOption "disable xhci wake during suspend to prevent wakes from usb devices";

  config = mkIf cfg.enable {
    systemd.services.systemd-suspend = {
      preStart = "${manageXhciWake} pre";
      postStop = "${manageXhciWake} post";
    };
  };
}
