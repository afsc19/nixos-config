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
    case "$phase" in
      pre)
        > "$STATE_FILE"
        for dev in /sys/bus/pci/devices/*/power/wakeup; do
            [ -f "$dev" ] || continue
            class=$(cat "$(dirname "$(dirname "$dev")")/class" 2>/dev/null) || continue
            # USB controller class = 0x0c0330 (USB xHCI)
            [ "$class" = "0x0c0330" ] || continue
            current=$(cat "$dev" 2>/dev/null)
            echo "$dev $current" >> "$STATE_FILE"
            echo "disabled" > "$dev" 2>/dev/null || true
        done
        ;;
      post)
        if [ -f "$STATE_FILE" ]; then
            while read -r dev state; do
                [ -f "$dev" ] || continue
                echo "$state" > "$dev" 2>/dev/null || true
            done < "$STATE_FILE"
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
