#!/usr/bin/env bash
# PurplePop - dfir-quick.sh
# Quick DFIR helper: basic triage and artifact pointers.

set -euo pipefail

echo "=== PurplePop :: DFIR Quick Triage ==="
echo

echo "[*] System info:"
uname -a
echo

echo "[*] Uptime:"
uptime
echo

echo "[*] Logged-in users:"
who || echo "  (no active sessions)"
echo

echo "[*] Mounted filesystems:"
lsblk -f | sed 's/^/  /'
echo

echo "[*] Recently mounted external devices (dmesg | tail):"
dmesg | tail -n 30 | sed 's/^/  /'
echo

echo "[*] Interesting directories to inspect on a mounted Windows disk:"
cat <<EOF
  - /mnt/windows/Windows/System32/config/
      * SAM, SYSTEM, SECURITY, SOFTWARE, DEFAULT hives
  - /mnt/windows/Users/<user>/
      * AppData/Local
      * AppData/Roaming
      * NTUSER.DAT
  - Prefetch: /mnt/windows/Windows/Prefetch
  - Event logs: /mnt/windows/Windows/System32/winevt/Logs
EOF
echo

echo "[*] Helpful tools in PurplePop for DFIR:"
cat <<EOF
  - sleuthkit: fls, mmls, istat, icat, tsk_recover
  - testdisk, ddrescue
  - foremost, scalpel, bulk_extractor
  - libesedb-tools (esent databases)
  - libpff-tools (PST/OST)
  - liblnk-tools (.lnk analysis)
  - regripper (registry)
EOF
echo

echo "[*] Example commands:"
cat <<'EOF'
  # List partitions on an image
  mmls disk-image.E01

  # Recover files from a partition
  tsk_recover -a /dev/sdX1 ./recovered/

  # Inspect a registry hive
  rip.pl -r /mnt/windows/Windows/System32/config/SOFTWARE -f software

  # Extract EXIF from a file
  exiftool suspicious.jpg
EOF

echo
echo "=== Done. Mount suspect media read-only and pivot deeper as needed. ==="
