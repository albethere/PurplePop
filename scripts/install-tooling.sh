#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-/mnt/chroot}"

run_chroot() {
  chroot "$ROOT" /usr/bin/env bash -c "$*"
}

# Update apt
run_chroot "apt-get update"

# Install from manifests
for mf in /manifests/apt-packages.*.txt; do
  echo "[*] Installing packages from $(basename "$mf")"
  pkgs=$(grep -vE '^\s*#' "$mf" | tr '\n' ' ')
  [ -z "$pkgs" ] || run_chroot "DEBIAN_FRONTEND=noninteractive apt-get install -y $pkgs"
done

# Clean up
run_chroot "apt-get clean && rm -rf /var/lib/apt/lists/*"
