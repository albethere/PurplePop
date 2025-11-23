#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[*] PurplePop :: build-iso.sh"
echo "[*] Project root: ${PROJECT_ROOT}"

BUILD_DIR="${PROJECT_ROOT}/.build"
mkdir -p "${BUILD_DIR}"

# 1. Download base Pop!_OS ISO if needed
"${PROJECT_ROOT}/scripts/download-base.sh"

# 2. Extract ISO and prepare chroot
"${PROJECT_ROOT}/scripts/create-chroot.sh"

CHROOT_DIR="${BUILD_DIR}/chroot"

# 3. Install tooling (apt packages, pipx tools) inside chroot
"${PROJECT_ROOT}/scripts/install-tooling.sh" "${CHROOT_DIR}"

# 4. Apply overlays (dotfiles, configs, custom scripts)
"${PROJECT_ROOT}/scripts/apply-overlays.sh" "${CHROOT_DIR}"


# 5. Configure live user + LightDM sessions (Sway/XFCE)
"${PROJECT_ROOT}/image/filesystem-hooks/20-configure-users.sh" "${CHROOT_DIR}"

# x. Any final chroot customizations can go here
# e.g. create default user, enable services, etc.
# "${PROJECT_ROOT}/image/filesystem-hooks/30-desktop-setup.sh" "${CHROOT_DIR}"

# 6. Finalize ISO
"${PROJECT_ROOT}/scripts/finalize-image.sh"

echo "[*] PurplePop build complete. Check the 'out/' directory for your ISO."
