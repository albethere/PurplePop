#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/.build"
BASE_DIR="${BUILD_DIR}/base"
ISO_PATH="${BASE_DIR}/pop-os_22.04_amd64.iso"

mkdir -p "${BASE_DIR}"

POP_ISO_URL="https://iso.pop-os.org/22.04/amd64/intel/58/pop-os_22.04_amd64_intel_58.iso"

if [ -f "${ISO_PATH}" ]; then
  echo "[*] Base Pop!_OS ISO already present at ${ISO_PATH}"
  exit 0
fi

echo "[*] Downloading Pop!_OS 22.04 ISO..."
curl -L "${POP_ISO_URL}" -o "${ISO_PATH}"

echo "[*] Download complete: ${ISO_PATH}"
echo "    (Optional) Add checksum verification here if desired."
#SHA256: 4e1c5e391062c79dc611ce383c2a709fecac36798ebd81444a734fd41252608e
