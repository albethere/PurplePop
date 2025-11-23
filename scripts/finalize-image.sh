#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/.build"
ISO_DIR="${BUILD_DIR}/iso-root"
CHROOT_DIR="${BUILD_DIR}/chroot"

# shellcheck source=lib/chroot.sh
source "${PROJECT_ROOT}/scripts/lib/chroot.sh"

if [ ! -d "${ISO_DIR}" ] || [ ! -d "${CHROOT_DIR}" ]; then
  echo "[!] ISO root or chroot directory missing."
  exit 1
fi

echo "[*] Unmounting chroot bind mounts..."
teardown_chroot_binds "${CHROOT_DIR}"

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

# Pop!_OS uses a hybrid BIOS/UEFI layout. Mirror the stock image flags so the
# remastered ISO remains bootable on both legacy and modern systems.
BIOS_ELTORITO="isolinux/isolinux.bin"
EFI_ELTORITO="boot/grub/efi.img"
MBR_TEMPLATE="/usr/lib/ISOLINUX/isohdpfx.bin"
if [ ! -e "${MBR_TEMPLATE}" ] && [ -e "/usr/lib/syslinux/isohdpfx.bin" ]; then
  MBR_TEMPLATE="/usr/lib/syslinux/isohdpfx.bin"
fi

for path in "${ISO_DIR}/${BIOS_ELTORITO}" "${ISO_DIR}/${EFI_ELTORITO}" "${MBR_TEMPLATE}"; do
  if [ ! -e "${path}" ]; then
    echo "[!] Missing required boot artifact: ${path}"
    exit 1
  fi
done

xorriso -as mkisofs \
  -r -V "PURPLEPOP" \
  -o "${FINAL_ISO}" \
  -J -l -cache-inodes \
    -isohybrid-mbr "${MBR_TEMPLATE}" \
  -partition_offset 16 \
  -b "${BIOS_ELTORITO}" \
  -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot \
  -e "${EFI_ELTORITO}" \
  -no-emul-boot -isohybrid-gpt-basdat \
  "${ISO_DIR}"

echo "[*] Final ISO created: ${FINAL_ISO}"
echo "    You can now flash it to USB or use with Ventoy."
