#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASHOURCE[0]}")/.." && pwd)" 2>/dev/null || \
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/.build"
BASE_DIR="${BUILD_DIR}/base"
ISO_PATH="${BASE_DIR}/pop-os_22.04_amd64.iso"

ISO_DIR="${BUILD_DIR}/iso-root"
CHROOT_DIR="${BUILD_DIR}/chroot"

mkdir -p "${ISO_DIR}" "${CHROOT_DIR}"

if [ ! -f "${ISO_PATH}" ]; then
  echo "[!] Base ISO not found at ${ISO_PATH}"
  echo "    Run scripts/download-base.sh first."
  exit 1
fi

echo "[*] Extracting ISO to ${ISO_DIR}..."
rm -rf "${ISO_DIR:?}"/*
bsdtar -C "${ISO_DIR}" -xf "${ISO_PATH}"

if [ ! -f "${ISO_DIR}/casper/filesystem.squashfs" ]; then
  echo "[!] Could not find casper/filesystem.squashfs in ISO."
  exit 1
fi

echo "[*] Unsquashing root filesystem into ${CHROOT_DIR}..."
rm -rf "${CHROOT_DIR:?}"/*
unsquashfs -f -d "${CHROOT_DIR}" "${ISO_DIR}/casper/filesystem.squashfs"

echo "[*] Binding system dirs into chroot..."
mount --bind /dev "${CHROOT_DIR}/dev"
mount --bind /dev/pts "${CHROOT_DIR}/dev/pts"
mount -t proc /proc "${CHROOT_DIR}/proc"
mount -t sysfs /sys "${CHROOT_DIR}/sys"
mount -t tmpfs tmpfs "${CHROOT_DIR}/run"

echo "[*] Chroot is ready at ${CHROOT_DIR}"
