#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /path/to/chroot"
  exit 1
fi

ROOT="$1"
LIVE_USER="${LIVE_USER:-purplepop}"
LIVE_SHELL="${LIVE_SHELL:-/usr/bin/zsh}"
DEFAULT_SESSION="${DEFAULT_SESSION:-sway}"

echo "[*] Configuring live user '${LIVE_USER}' inside ${ROOT}..."

CHROOT_RUN=(chroot "${ROOT}" /usr/bin/env bash -e -c)

if ! "${CHROOT_RUN[@]}" "id -u ${LIVE_USER} >/dev/null 2>&1"; then
  "${CHROOT_RUN[@]}" "useradd -m -s ${LIVE_SHELL} -G sudo,adm,cdrom,plugdev ${LIVE_USER}"
else
  "${CHROOT_RUN[@]}" "usermod -s ${LIVE_SHELL} ${LIVE_USER}"
fi

"${CHROOT_RUN[@]}" "passwd -d ${LIVE_USER}"

LIVE_HOME="/home/${LIVE_USER}"
if [ -d "${ROOT}${LIVE_HOME}" ]; then
  "${CHROOT_RUN[@]}" "chown -R ${LIVE_USER}:${LIVE_USER} ${LIVE_HOME}"
fi

echo "[*] Setting LightDM as the display manager and defaulting to ${DEFAULT_SESSION}..."
echo "/usr/sbin/lightdm" > "${ROOT}/etc/X11/default-display-manager"

LIGHTDM_CONF_DIR="${ROOT}/etc/lightdm/lightdm.conf.d"
mkdir -p "${LIGHTDM_CONF_DIR}"
cat > "${LIGHTDM_CONF_DIR}/50-purplepop.conf" <<EOF
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=${DEFAULT_SESSION}
EOF

systemctl --root "${ROOT}" enable lightdm.service

echo "[*] LightDM configured. Sway and XFCE sessions will be available via the greeter."