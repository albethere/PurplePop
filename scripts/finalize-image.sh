#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/.build"
ISO_DIR="${BUILD_DIR}/iso-root"
CHROOT_DIR="${BUILD_DIR}/chroot"

if [ ! -d "${ISO_DIR}" ] || [ ! -d "${CHROOT_DIR}" ]; then
  echo "[!] ISO root or chroot directory missing."
  exit 1
fi

echo "[*] Unmounting chroot bind mounts..."
for mnt in dev/pts dev proc sys run; do
  if mountpoint -q "${CHROOT_DIR}/${mnt}"; then
    umount "${CHROOT_DIR}/${mnt}"
  fi
done

echo "[*] Rebuilding filesystem.squashfs..."
rm -f "${ISO_DIR}/casper/filesystem.squashfs"
mksquashfs "${CHROOT_DIR}" "${ISO_DIR}/casper/filesystem.squashfs" -b 1048576 -comp xz -Xbcj x86

echo "[*] Updating filesystem.size..."
du -sx --block-size=1 "${CHROOT_DIR}" | cut -f1 > "${ISO_DIR}/casper/filesystem.size"

echo "[*] Creating final PurplePop ISO..."
OUT_DIR="${PROJECT_ROOT}/out"
mkdir -p "${OUT_DIR}"
ISO_NAME="PurplePop-$(date +%Y%m%d).iso"
FINAL_ISO="${OUT_DIR}/${ISO_NAME}"

# NOTE: This xorriso line is generic for Ubuntu-like ISOs.
# Depending on Pop!_OS internals, you might tweak boot options later.
xorriso -as mkisofs \
  -r -V "PURPLEPOP" \
  -o "${FINAL_ISO}" \
  -J -l -cache-inodes \
  "${ISO_DIR}"

echo "[*] Final ISO created: ${FINAL_ISO}"
echo "    You can now flash it to USB or use with Ventoy."
