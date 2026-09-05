#!/usr/bin/env bash
# Diagnose RTL8822BU (rtw88_8822bu) WiFi freeze on family11
# Run this immediately after a freeze or during one to capture state.
# Distinguishes between soft stalls (driver alive) and hard crashes (driver/USB gone).
# Output is saved to diagnose-wifi.log in the same directory as this script.
#
# Run as root: sudo ./diagnose-wifi.sh
# (required for dmesg access — without sudo, kernel log sections will be empty)

set -euo pipefail

LOGFILE="$(dirname "$0")/diagnose-wifi.log"
exec > >(tee "$LOGFILE") 2>&1
echo "=== diagnose-wifi run: $(date) ==="

echo "=== USB device enumerated? ==="
if lsusb | grep -q "0bda:b812"; then
  echo "YES: 0bda:b812 is on the USB bus (USB layer is OK)"
else
  echo "NO: 0bda:b812 is MISSING from USB bus (USB crash or physical disconnect)"
fi

echo ""
echo "=== Loaded driver modules ==="
lsmod | grep -E 'rtw88' || echo "(no rtw88 module loaded — driver crashed or was unloaded)"

echo ""
echo "=== WiFi interfaces ==="
ip link show | grep -E 'wl|state' || echo "(no wireless interface)"

echo ""
echo "=== NetworkManager state ==="
nmcli general status 2>/dev/null || echo "(nmcli unavailable)"
echo ""
nmcli device status 2>/dev/null | grep -E 'TYPE|wifi|wl' || echo "(no devices)"

echo ""
echo "=== USB power/control for 0bda:b812 ==="
found=0
for dev in /sys/bus/usb/devices/*/idVendor; do
  dir=$(dirname "$dev")
  vendor=$(cat "$dev" 2>/dev/null)
  product=$(cat "$dir/idProduct" 2>/dev/null)
  if [[ "$vendor" == "0bda" && "$product" == "b812" ]]; then
    found=1
    echo "  device: $dir"
    echo "  power/control: $(cat "$dir/power/control" 2>/dev/null)"
    echo "  power/runtime_status: $(cat "$dir/power/runtime_status" 2>/dev/null)"
    echo "  power/autosuspend_delay_ms: $(cat "$dir/power/autosuspend_delay_ms" 2>/dev/null)"
  fi
done
[[ $found -eq 0 ]] && echo "  (device not found in sysfs — USB crash)"

echo ""
echo "=== dmesg (last 120s, rtw/usb/wifi related) ==="
dmesg --since "120 seconds ago" | grep -iE 'rtw|8822|wifi|wlan|firmware|tx report|watchdog|usb.*error|reset|disconnect|timeout' || echo "(none)"

echo ""
echo "=== dmesg USB errors (all time, last 20) ==="
dmesg | grep -iE 'usb.*0bda|0bda.*usb|usb.*b812|b812.*usb|usb.*reset|xhci.*error' | tail -20 || echo "(none)"

echo ""
echo "=== iwconfig ==="
iw dev 2>/dev/null || echo "(unavailable)"

echo ""
echo "=== TX/RX stats ==="
iw dev 2>/dev/null | grep -E 'Interface|txpower|channel|width' || true
ip -s link show 2>/dev/null | grep -A5 'wl' || echo "(no wireless link stats)"

echo ""
echo "=== Diagnosis summary ==="
usb_present=$(lsusb | grep -c "0bda:b812" || true)
mod_loaded=$(lsmod | grep -c "rtw88_8822bu" || true)
txpower=$(iw dev 2>/dev/null | awk '/txpower/{print $2}')
if [[ $usb_present -eq 0 ]]; then
  echo "HARD CRASH: USB device disappeared. Unplug/replug adapter, then run recover-wifi.sh"
elif [[ $mod_loaded -eq 0 ]]; then
  echo "DRIVER CRASH: USB device present but rtw88_8822bu not loaded. Run: sudo ./recover-wifi.sh"
elif [[ "$txpower" == "-100.00" ]]; then
  echo "FIRMWARE CRASH: USB present, driver loaded, but txpower=-100 dBm (radio is dead)."
  echo "  Module reload alone won't fix this — recover-wifi.sh will USB-reset the adapter."
  echo "  Run: sudo ./recover-wifi.sh"
else
  echo "SOFT FAILURE: USB present, driver loaded. Likely NM or firmware state. Run: sudo ./recover-wifi.sh"
fi
