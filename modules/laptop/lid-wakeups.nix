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

  manageUsbWakeup = pkgs.writeShellScript "manage-usb-wakeup.sh" ''
    LID_STATE=$(cat /proc/acpi/button/lid/*/state | awk '{print $2}')
    MONITOR_CONNECTED=$(grep -q "connected" /sys/class/drm/card*-*/status && echo "yes" || echo "no")

    # lid closed and no monitors
    if [ "$LID_STATE" = "closed" ] && [ "$MONITOR_CONNECTED" = "no" ]; then
        for dev in /sys/bus/usb/devices/*/power/wakeup; do
            echo "disabled" > "$dev" 2>/dev/null
        done
    else
        # re-enable once you open the lid
        for dev in /sys/bus/usb/devices/*/power/wakeup; do
            echo "enabled" > "$dev" 2>/dev/null
        done
    fi
  '';
in
{
  options.modules.laptop.lid-wakeups.enable =
    mkEnableOption "Disable usb waking from suspended when the lid is closed and there are no external monitors";

  config = mkIf cfg.enable {
    services.udev.extraRules = ''
      SUBSYSTEM=="acpi", ACTION=="change", KERNEL=="button", DEVPATH=="*/button/lid", RUN+="${manageUsbWakeup}"
    '';
  };
}
