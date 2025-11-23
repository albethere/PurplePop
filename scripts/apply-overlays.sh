#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /path/to/chroot"
  exit 1
fi

ROOT="$1"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OVERLAY_DIR="${PROJECT_ROOT}/iso/overlay"

if [ ! -d "${OVERLAY_DIR}" ]; then
  echo "[!] Overlay dir ${OVERLAY_DIR} not found."
  exit 1
fi

echo "[*] Applying overlay from ${OVERLAY_DIR} to ${ROOT}..."
rsync -a "${OVERLAY_DIR}/" "${ROOT}/"

# Ensure /usr/local/bin tools inside chroot are executable
if [ -d "${ROOT}/usr/local/bin" ]; then
  echo "[*] Marking /usr/local/bin scripts executable inside chroot..."
  chroot "${ROOT}" /usr/bin/env bash -c "chmod -R a+rx /usr/local/bin"
fi

echo "[*] Overlay applied."
