#!/usr/bin/env bash
# Diagnose RTL8822BU (88x2bu) WiFi freeze on family11
# Run this immediately after a freeze or during one to capture state

set -euo pipefail

echo "=== WiFi interface ==="
ip link show | grep -E 'wl|state'

echo ""
echo "=== Loaded driver module ==="
lsmod | grep -E '88x2bu|rtw88'

echo ""
echo "=== Module parameters (power management) ==="
for p in rtw_power_mgnt rtw_ips_mode rtw_lps_level rtw_lps_delay; do
  val=$(cat /sys/module/88x2bu/parameters/$p 2>/dev/null || echo "not found")
  echo "  $p = $val"
done

echo ""
echo "=== USB power/control for 0bda:b812 ==="
for dev in /sys/bus/usb/devices/*/idVendor; do
  dir=$(dirname "$dev")
  vendor=$(cat "$dev" 2>/dev/null)
  product=$(cat "$dir/idProduct" 2>/dev/null)
  if [[ "$vendor" == "0bda" && "$product" == "b812" ]]; then
    echo "  device: $dir"
    echo "  power/control: $(cat "$dir/power/control" 2>/dev/null)"
    echo "  power/runtime_status: $(cat "$dir/power/runtime_status" 2>/dev/null)"
    echo "  power/autosuspend_delay_ms: $(cat "$dir/power/autosuspend_delay_ms" 2>/dev/null)"
  fi
done

echo ""
echo "=== dmesg (last 60s, rtw/wifi related) ==="
dmesg --since "60 seconds ago" | grep -iE 'rtw|8822|wifi|wlan|88x2bu|firmware|tx report|watchdog' || echo "(none)"

echo ""
echo "=== iwconfig ==="
iwconfig 2>/dev/null || iw dev

echo ""
echo "=== TX queue stats ==="
iw dev wlp0s20u1 station dump 2>/dev/null || \
  ip -s link show | grep -A5 'wl'
