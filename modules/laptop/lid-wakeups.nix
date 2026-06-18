# Custom acpi script to disable usb waking from suspended when the lid is closed and there are no external monitors (yes I use this on my personal laptops)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.laptop.lid-wakeups;

  # systemd-sleep will then call this as ./<script> {pre,post} {suspend,hibernate,etc}
  manageUsbWakeup = pkgs.writeShellScript "manage-usb-wakeup.sh" ''
    phase=$1
    case "$phase" in
      pre)
        LID_CLOSED=$(grep -c "closed" /proc/acpi/button/lid/*/state)
        MONITOR_CONNECTED=$(grep -x "connected" /sys/class/drm/card*-*/status 2>/dev/null | grep -v "eDP" | grep -q "connected" && echo "yes" || echo "no")

        if [ "$LID_CLOSED" -ge 1 ] && [ "$MONITOR_CONNECTED" = "no" ]; then
            for dev in /sys/bus/usb/devices/*/power/wakeup; do
                echo "disabled" > "$dev" 2>/dev/null
            done
        fi
        ;;
      post)
        for dev in /sys/bus/usb/devices/*/power/wakeup; do
            echo "enabled" > "$dev" 2>/dev/null
        done
        ;;
    esac
  '';
in
{
  options.modules.laptop.lid-wakeups.enable =
    mkEnableOption "Disable usb waking from suspended when the lid is closed and there are no external monitors";

  config = mkIf cfg.enable {
    systemd.services.systemd-suspend = {
      preStart = "${manageUsbWakeup} pre";
      postStop = "${manageUsbWakeup} post";
    };
  };
}
