#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /path/to/chroot"
  exit 1
fi

ROOT="$1"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OVERLAY_DIR="${PROJECT_ROOT}/iso/overlay"
DOTFILES_DIR="${PROJECT_ROOT}/dotfiles"

if [ ! -d "${OVERLAY_DIR}" ]; then
  echo "[!] Overlay dir ${OVERLAY_DIR} not found."
  exit 1
fi

echo "[*] Applying raw overlay from ${OVERLAY_DIR} to ${ROOT}..."
rsync -a "${OVERLAY_DIR}/" "${ROOT}/"

# ------------------------------------------------------------------------------
# Sync dotfiles into /etc/skel so the live user inherits them
# ------------------------------------------------------------------------------

SKEL="${ROOT}/etc/skel"
mkdir -p "${SKEL}"

echo "[*] Populating /etc/skel from dotfiles..."

# zsh config
if [ -f "${DOTFILES_DIR}/zsh/.zshrc" ]; then
  install -Dm644 "${DOTFILES_DIR}/zsh/.zshrc" "${SKEL}/.zshrc"
fi

# optional extra zsh bits (aliases, prompt)
mkdir -p "${SKEL}/.config/zsh"
for f in aliases.zsh prompt.zsh; do
  if [ -f "${DOTFILES_DIR}/zsh/${f}" ]; then
    install -Dm644 "${DOTFILES_DIR}/zsh/${f}" "${SKEL}/.config/zsh/${f}"
  fi
done

# sway config
if [ -d "${DOTFILES_DIR}/sway" ]; then
  mkdir -p "${SKEL}/.config/sway"
  rsync -a "${DOTFILES_DIR}/sway/." "${SKEL}/.config/sway/"
fi

# waybar config
if [ -d "${DOTFILES_DIR}/waybar" ]; then
  mkdir -p "${SKEL}/.config/waybar"
  rsync -a "${DOTFILES_DIR}/waybar/." "${SKEL}/.config/waybar/"
fi

# XFCE config
if [ -d "${DOTFILES_DIR}/xfce" ]; then
  # panel + desktop XML
  mkdir -p "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml"
  [ -f "${DOTFILES_DIR}/xfce/xfce4-panel.xml" ] && \
    install -Dm644 "${DOTFILES_DIR}/xfce/xfce4-panel.xml" \
      "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
  [ -f "${DOTFILES_DIR}/xfce/xfce4-desktop.xml" ] && \
    install -Dm644 "${DOTFILES_DIR}/xfce/xfce4-desktop.xml" \
      "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"

  # terminal config
  if [ -f "${DOTFILES_DIR}/xfce/terminalrc" ]; then
    mkdir -p "${SKEL}/.config/xfce4/terminal"
    install -Dm644 "${DOTFILES_DIR}/xfce/terminalrc" \
      "${SKEL}/.config/xfce4/terminal/terminalrc"
  fi
fi

# Waveterm config
if [ -d "${DOTFILES_DIR}/waveterm" ]; then
  mkdir -p "${SKEL}/.config/waveterm"
  rsync -a "${DOTFILES_DIR}/waveterm/." "${SKEL}/.config/waveterm/"
fi

# Git config
if [ -f "${DOTFILES_DIR}/git/.gitconfig" ]; then
  install -Dm644 "${DOTFILES_DIR}/git/.gitconfig" "${SKEL}/.gitconfig"
fi

# ------------------------------------------------------------------------------
# Permissions for tools installed into /usr/local/bin inside chroot
# ------------------------------------------------------------------------------

if [ -d "${ROOT}/usr/local/bin" ]; then
  echo "[*] Marking /usr/local/bin scripts executable inside chroot..."
  chroot "${ROOT}" /usr/bin/env bash -c "chmod -R a+rx /usr/local/bin"
fi

echo "[*] Overlay + /etc/skel population complete."
