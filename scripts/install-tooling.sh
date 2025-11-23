#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /path/to/chroot"
  exit 1
fi

ROOT="$1"

run_chroot() {
  chroot "${ROOT}" /usr/bin/env bash -c "$*"
}

echo "[*] Copying manifests into chroot..."
mkdir -p "${ROOT}/manifests"
cp -a manifests/*.txt "${ROOT}/manifests/"

echo "[*] Updating apt sources inside chroot..."
run_chroot "apt-get update"

# Install apt packages from each manifest
for mf in /manifests/apt-packages*.txt; do
  run_chroot "test -f '${mf}'" || continue
  echo "[*] Installing packages from ${mf}"
  pkgs=$(chroot "${ROOT}" awk '!/^($|#)/ {printf \"%s \", \$1}' "${mf}")
  if [ -n "${pkgs}" ]; then
    run_chroot "DEBIAN_FRONTEND=noninteractive apt-get install -y ${pkgs}"
  fi
done

# Optional: pipx + pipx-tools
if [ -f "${ROOT}/manifests/pipx-tools.txt" ]; then
  echo "[*] Installing pipx and pipx tools..."
  run_chroot "apt-get install -y pipx"
  run_chroot "pipx ensurepath || true"

  while IFS= read -r tool; do
    [ -z "${tool}" ] && continue
    case "${tool}" in
      \#*) continue ;;
    esac
    echo "  - pipx install ${tool}"
    run_chroot "pipx install ${tool} || true"
  done < "${ROOT}/manifests/pipx-tools.txt"
fi

echo "[*] Cleaning apt cache..."
run_chroot "apt-get clean && rm -rf /var/lib/apt/lists/*"
