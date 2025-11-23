#!/usr/bin/env python3
"""Utility for loading and validating Pop!_OS base image metadata."""

import argparse
import importlib
import importlib.util
import pathlib
import re
import sys
import urllib.parse
from typing import Dict, Mapping, Optional

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
DEFAULT_METADATA_PATH = REPO_ROOT / "image" / "base-popos.yaml"


class MetadataError(RuntimeError):
    """Raised when the Pop!_OS metadata is missing or malformed."""


def _load_yaml_module() -> Optional[object]:
    spec = importlib.util.find_spec("yaml")
    if spec is None or spec.loader is None:
        return None

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _parse_metadata(path: pathlib.Path) -> Mapping[str, object]:
    if not path.exists():
        raise MetadataError(f"Metadata file not found: {path}")

    contents = path.read_text(encoding="utf-8")

    yaml_module = _load_yaml_module()
    if yaml_module:
        try:
            data = yaml_module.safe_load(contents)
        except Exception as exc:
            raise MetadataError(f"Failed to parse YAML: {exc}") from exc
    else:
        data = None

    if data is None:
        data = {}
        for lineno, raw_line in enumerate(contents.splitlines(), 1):
            stripped = raw_line.split("#", 1)[0].strip()
            if not stripped:
                continue
            if ":" not in stripped:
                raise MetadataError(
                    f"Invalid metadata line {lineno}: '{raw_line}' (expected key: value)"
                )
            key, value = stripped.split(":", 1)
            key = key.strip()
            value = value.strip()
            if value.startswith('"') and value.endswith('"') and len(value) >= 2:
                value = value[1:-1]
            data[key] = value

    if not isinstance(data, dict):
        raise MetadataError("Metadata file must contain a mapping at the top level.")

    return data


def _validate(data: Mapping[str, object]) -> Dict[str, str]:
    required = ("filename", "url", "sha256")
    missing = [key for key in required if key not in data]
    if missing:
        raise MetadataError(f"Missing required metadata keys: {', '.join(missing)}")

    values: Dict[str, str] = {}
    for key in required:
        raw_value = data.get(key, "")
        if not isinstance(raw_value, str):
            raise MetadataError(f"Metadata field '{key}' must be a string")
        value = raw_value.strip()
        if not value:
            raise MetadataError(f"Metadata field '{key}' must be non-empty")
        values[key] = value

    filename = pathlib.Path(values["filename"]).name
    if filename != values["filename"] or "/" in values["filename"]:
        raise MetadataError("Metadata filename may not contain path separators")

    parsed_url = urllib.parse.urlparse(values["url"])
    if parsed_url.scheme not in {"http", "https"} or not parsed_url.netloc:
        raise MetadataError("Metadata URL must be absolute and use http/https")

    if not re.fullmatch(r"[0-9a-fA-F]{64}", values["sha256"]):
        raise MetadataError("Metadata sha256 must be a 64-character hexadecimal string")

    values["filename"] = filename
    values["sha256"] = values["sha256"].lower()
    return values


def load_metadata(path: pathlib.Path) -> Dict[str, str]:
    return _validate(_parse_metadata(path))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--metadata-path",
        type=pathlib.Path,
        default=DEFAULT_METADATA_PATH,
        help="Path to the Pop!_OS metadata file",
    )
    parser.add_argument(
        "--value",
        action="append",
        choices=["filename", "url", "sha256"],
        help="Print only the specified value(s) in request order",
    )
    args = parser.parse_args()

    try:
        metadata = load_metadata(args.metadata_path)
    except MetadataError as exc:
        print(f"[!] {exc}", file=sys.stderr)
        return 1

    fields = args.value or ["filename", "url", "sha256"]
    for field in fields:
        print(metadata[field])

    return 0


if __name__ == "__main__":
    raise SystemExit(main())