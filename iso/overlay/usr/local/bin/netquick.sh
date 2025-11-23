#!/usr/bin/env bash
# PurplePop - netquick.sh
# Quick network triage helper for live sessions.

set -euo pipefail

echo "=== PurplePop :: Network Quick Check ==="
echo

HOSTNAME="$(hostname)"
echo "[*] Hostname: $HOSTNAME"
echo

echo "[*] IP configuration (ip addr):"
ip addr show | sed 's/^/  /'
echo

echo "[*] Default routes:"
ip route show | sed 's/^/  /'
echo

echo "[*] DNS configuration (/etc/resolv.conf):"
sed 's/^/  /' /etc/resolv.conf || echo "  (no resolv.conf)"
echo

echo "[*] Active TCP/UDP connections (ss -tuna):"
ss -tuna | sed 's/^/  /' | head -n 40
echo "  ... (truncated to 40 lines)"
echo

echo "[*] Top 10 processes by CPU (btop/ps fallback):"
if command -v btop >/dev/null 2>&1; then
  echo "  Launching btop (press q to exit)..."
  btop
else
  ps aux --sort=-%cpu | head -n 11 | sed 's/^/  /'
fi

echo
echo "[*] Quick ping test (8.8.8.8):"
if ping -c 3 -W 1 8.8.8.8 >/dev/null 2>&1; then
  echo "  OK: reachable"
else
  echo "  FAIL: no response from 8.8.8.8"
fi

echo
echo "=== Done. Use 'wireshark', 'tshark', 'nmap', etc. for deeper work. ==="
