#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${PROJECT_DIR}/.build"
CHROOT_DIR="${WORK_DIR}/chroot"
ISO_DIR="${WORK_DIR}/iso"
UBUNTU_ISO="${WORK_DIR}/ubuntu-base.iso"

mkdir -p "$WORK_DIR" "$CHROOT_DIR" "$ISO_DIR"

# 1. Download base ISO if not present
if [ ! -f "$UBUNTU_ISO" ]; then
  "${PROJECT_DIR}/scripts/download-base.sh" "$UBUNTU_ISO"
fi

# 2. Extract ISO and root filesystem (casper squashfs)
echo "[*] Extracting base ISO..."
# Example using bsdtar + unsquashfs; you'll adapt to your base ISO layout
bsdtar -C "$ISO_DIR" -xf "$UBUNTU_ISO"
unsquashfs -f -d "$CHROOT_DIR" "$ISO_DIR/casper/filesystem.squashfs"

# 3. Mount proc/sys/dev inside chroot
mount --bind /dev  "$CHROOT_DIR/dev"
mount --bind /dev/pts "$CHROOT_DIR/dev/pts"
mount -t proc /proc "$CHROOT_DIR/proc"
mount -t sysfs /sys "$CHROOT_DIR/sys"

# 4. Copy manifests and overlay into chroot
cp -r "${PROJECT_DIR}/manifests" "$CHROOT_DIR/"
rsync -a "${PROJECT_DIR}/iso/overlay/" "$CHROOT_DIR/"

# 5. Install packages and configs
"${PROJECT_DIR}/scripts/install-tooling.sh" "$CHROOT_DIR"
"${PROJECT_DIR}/scripts/apply-overlays.sh" "$CHROOT_DIR"

# 6. Configure users, DM, default session, etc.
"${PROJECT_DIR}/scripts/30-desktop-setup.sh" "$CHROOT_DIR"

# 7. Clean up chroot
chroot "$CHROOT_DIR" /usr/bin/env bash -c "apt-get clean; rm -rf /tmp/* /var/tmp/*"

# 8. Rebuild squashfs and ISO
echo "[*] Rebuilding squashfs..."
mksquashfs "$CHROOT_DIR" "$ISO_DIR/casper/filesystem.squashfs" -b 1048576 -comp xz -Xbcj x86

# Update filesystem.size if needed
printf "$(du -sx --block-size=1 "$CHROOT_DIR" | cut -f1)" > "$ISO_DIR/casper/filesystem.size"

echo "[*] Creating final ISO..."
FINAL_ISO="${PROJECT_DIR}/purple-usb-$(date +%Y%m%d).iso"
xorriso -as mkisofs \
  -r -V "PURPLEUSB" \
  -o "$FINAL_ISO" \
  -J -l -cache-inodes \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  "$ISO_DIR"

echo "[*] Done -> $FINAL_ISO"
