#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/.build"
BASE_DIR="${BUILD_DIR}/base"
metadata_output=$("${PROJECT_ROOT}/scripts/helpers/read_popos_metadata.py" --value filename --value url --value sha256) || exit 1

read -r POP_ISO_FILENAME POP_ISO_URL POP_ISO_SHA256 <<< "${metadata_output}"

ISO_PATH="${BASE_DIR}/${POP_ISO_FILENAME}"

mkdir -p "${BASE_DIR}"

if [ -f "${ISO_PATH}" ]; then
  if echo "${POP_ISO_SHA256}  ${ISO_PATH}" | sha256sum -c --status; then
    echo "[*] Base Pop!_OS ISO already present and verified at ${ISO_PATH}"
    exit 0
  fi

  echo "[!] Existing ISO at ${ISO_PATH} failed checksum. Re-downloading..." >&2
  rm -f "${ISO_PATH}"
fi

echo "[*] Downloading Pop!_OS 22.04 ISO from ${POP_ISO_URL}..."
TEMP_ISO_PATH=$(mktemp "${BASE_DIR}/popos-download.XXXXXX")

if ! curl \
  --fail \
  --location \
  --retry 3 \
  --retry-delay 5 \
  --retry-connrefused \
  --connect-timeout 20 \
  --output "${TEMP_ISO_PATH}" \
  "${POP_ISO_URL}"; then
  echo "[!] Failed to download ISO from ${POP_ISO_URL}" >&2
  rm -f "${TEMP_ISO_PATH}"
  exit 1
fi

if ! echo "${POP_ISO_SHA256}  ${TEMP_ISO_PATH}" | sha256sum -c --status; then
  echo "[!] Checksum verification failed for ${TEMP_ISO_PATH}" >&2
  rm -f "${TEMP_ISO_PATH}"
  exit 1
fi

mv -f "${TEMP_ISO_PATH}" "${ISO_PATH}"
echo "[*] Download complete and verified: ${ISO_PATH}"