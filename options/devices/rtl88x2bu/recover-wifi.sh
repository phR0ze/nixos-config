#!/usr/bin/env bash
# Recover RTL8822BU (rtw88_8822bu) WiFi after a complete dropout
#
# Try this before rebooting. It unloads the driver stack, USB-resets the adapter,
# reloads the driver, and restarts NetworkManager. Works if the USB device is still
# enumerated but the driver or NM state has gone bad.
#
# Run as root: sudo ./recover-wifi.sh
# Output is saved to recover-wifi.log in the same directory as this script.

set -euo pipefail

LOGFILE="$(dirname "$0")/recover-wifi.log"
exec > >(tee "$LOGFILE") 2>&1
echo "=== recover-wifi run: $(date) ==="

echo "=== USB device still present? ==="
if ! lsusb | grep -q "0bda:b812"; then
  echo "ERROR: 0bda:b812 not found on USB bus."
  echo "The adapter may have hard-crashed or been physically disconnected."
  echo "Try unplugging and replugging the adapter, then run this script again."
  exit 1
fi
echo "OK: 0bda:b812 is present on USB bus."

echo ""
echo "=== Current module state ==="
lsmod | grep -E 'rtw88' || echo "(no rtw88 module loaded)"

echo ""
echo "=== Unloading rtw88 driver stack ==="
# Unload in dependency order: device-specific first, then transport, then core
for mod in rtw88_8822bu rtw88_8822b rtw88_usb rtw88_core; do
  if lsmod | grep -q "^$mod "; then
    rmmod "$mod" && echo "OK: unloaded $mod" || echo "WARN: failed to unload $mod"
  else
    echo "(skipping $mod — not loaded)"
  fi
done

echo ""
echo "=== USB reset (power-cycles firmware state in adapter RAM) ==="
usb_devid=""
for dev in /sys/bus/usb/devices/*/idVendor; do
  dir=$(dirname "$dev")
  vendor=$(cat "$dev" 2>/dev/null)
  product=$(cat "$dir/idProduct" 2>/dev/null)
  if [[ "$vendor" == "0bda" && "$product" == "b812" ]]; then
    usb_devid=$(basename "$dir")
    break
  fi
done
if [[ -n "$usb_devid" ]]; then
  echo "  Unbinding $usb_devid..."
  echo "$usb_devid" > /sys/bus/usb/drivers/usb/unbind
  sleep 2
  echo "  Rebinding $usb_devid..."
  echo "$usb_devid" > /sys/bus/usb/drivers/usb/bind
  sleep 2
  echo "  USB reset complete"
else
  echo "  WARN: could not find device in sysfs to reset"
fi

echo ""
echo "=== Reloading rtw88_8822bu ==="
modprobe rtw88_8822bu
sleep 2

echo ""
echo "=== Module loaded? ==="
lsmod | grep rtw88_8822bu || { echo "ERROR: rtw88_8822bu failed to load"; exit 1; }

echo ""
echo "=== Interface up? ==="
ip link show | grep -E 'wl' || echo "(no wireless interface yet)"

echo ""
echo "=== Restarting NetworkManager ==="
systemctl restart NetworkManager
sleep 3

echo ""
echo "=== NM status ==="
nmcli general status
echo ""
nmcli device status | grep -E 'wifi|wl' || echo "(no wifi device in NM)"

echo ""
echo "Done. If NM shows the wifi device, try: nmcli connection up <profile-name>"
echo "Or wait ~10s for NM to auto-connect."
