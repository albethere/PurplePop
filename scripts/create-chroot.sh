#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" 2>/dev/null || \
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/.build"
BASE_DIR="${BUILD_DIR}/base"
METADATA_PATH="${PROJECT_ROOT}/image/base-popos.yaml"

ISO_FILENAME=$(python - <<'PY'
import pathlib
import sys

metadata_path = pathlib.Path("${METADATA_PATH}")

if not metadata_path.exists():
    print(f"[!] Metadata file not found: {metadata_path}", file=sys.stderr)
    sys.exit(1)

def parse_simple_yaml(path: pathlib.Path):
    data = {}
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith('#'):
            continue
        if ':' not in line:
            continue
        key, value = line.split(':', 1)
        key = key.strip()
        value = value.strip()
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
        data[key] = value
    return data

data = parse_simple_yaml(metadata_path)
filename = data.get("filename", "").strip()
if not filename:
    print("[!] ISO filename missing from metadata.", file=sys.stderr)
    sys.exit(1)

print(filename)
PY
) || exit 1
ISO_PATH="${BASE_DIR}/${ISO_FILENAME}"

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