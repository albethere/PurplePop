#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/.build"
BASE_DIR="${BUILD_DIR}/base"
METADATA_PATH="${PROJECT_ROOT}/image/base-popos.yaml"

metadata_output=$(python - <<'PY'
import json
import pathlib
import sys

metadata_path = pathlib.Path("${METADATA_PATH}")

if not metadata_path.exists():
    print(f"Missing metadata file at {metadata_path}", file=sys.stderr)
    sys.exit(1)

try:
    data = json.load(metadata_path.open())
except json.JSONDecodeError as exc:
    print(f"Failed to parse metadata: {exc}", file=sys.stderr)
    sys.exit(1)

required = ("filename", "url", "sha256")
missing = [key for key in required if key not in data]
if missing:
    print(f"Missing required metadata keys: {', '.join(missing)}", file=sys.stderr)
    sys.exit(1)

for key in required:
    value = data[key]
    if not isinstance(value, str) or not value.strip():
        print(f"Metadata field '{key}' must be a non-empty string", file=sys.stderr)
        sys.exit(1)
    print(value)
PY
) || exit 1

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
curl -L "${POP_ISO_URL}" -o "${ISO_PATH}"

if ! echo "${POP_ISO_SHA256}  ${ISO_PATH}" | sha256sum -c --status; then
  echo "[!] Checksum verification failed for ${ISO_PATH}" >&2
  exit 1
fi

echo "[*] Download complete and verified: ${ISO_PATH}"