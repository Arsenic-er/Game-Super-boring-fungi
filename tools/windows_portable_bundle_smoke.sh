#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/fungi-windows-portable-bundle.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

archive_path="$temp_dir/FungiMicroculture-Windows-x64.zip"

GODOT_BIN="${GODOT_BIN:-/home/ubuntu/fungi/tools/godot/4.7/godot}" \
	"$repo_root/tools/package_windows_portable.sh" "$archive_path"

python3 - "$archive_path" <<'PY'
import sys
import zipfile

archive_path = sys.argv[1]
expected = {
    "FungiMicroculture.exe",
    "FungiMicroculture.pck",
    "README-FIRST.txt",
}

with zipfile.ZipFile(archive_path) as archive:
    names = set(archive.namelist())
    if names != expected:
        raise SystemExit(
            "WINDOWS_PORTABLE_BUNDLE_FAIL: expected root entries "
            f"{sorted(expected)}, got {sorted(names)}"
        )
    empty = sorted(info.filename for info in archive.infolist() if info.file_size <= 0)
    if empty:
        raise SystemExit(
            "WINDOWS_PORTABLE_BUNDLE_FAIL: empty archive entries: " + ", ".join(empty)
        )

print("WINDOWS_PORTABLE_BUNDLE_OK: " + ", ".join(sorted(expected)))
PY
