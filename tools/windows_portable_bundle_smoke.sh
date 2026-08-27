#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/fungi-windows-portable-bundle.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

archive_path="$temp_dir/FungiMicroculture-Windows-x64.zip"

GODOT_BIN="${GODOT_BIN:-/home/ubuntu/fungi/tools/godot/4.7/godot}" \
	"$repo_root/tools/package_windows_portable.sh" "$archive_path"

python3 "$repo_root/tools/verify_windows_portable_zip.py" "$archive_path"

archive_mode="$(python3 -c 'import os, stat, sys; print(format(stat.S_IMODE(os.stat(sys.argv[1]).st_mode), "03o"))' "$archive_path")"
if [[ "$archive_mode" != "644" ]]; then
	printf 'WINDOWS_PORTABLE_BUNDLE_FAIL: archive mode must be 644, got %s\n' "$archive_mode" >&2
	exit 1
fi

printf 'WINDOWS_PORTABLE_BUNDLE_OK: verified packaged ZIP payload\n'

preserved_archive="$temp_dir/preserved-existing.zip"
printf 'previous-good-archive\n' >"$preserved_archive"

set +e
GODOT_BIN="${GODOT_BIN:-/home/ubuntu/fungi/tools/godot/4.7/godot}" \
	PYTHON_BIN=/bin/false \
	"$repo_root/tools/package_windows_portable.sh" "$preserved_archive" \
	>"$temp_dir/expected-package-failure.log" 2>&1
failure_status=$?
set -e

if [[ $failure_status -eq 0 ]]; then
	printf 'WINDOWS_PORTABLE_BUNDLE_FAIL: injected packaging failure unexpectedly succeeded\n' >&2
	exit 1
fi

if [[ "$(cat "$preserved_archive")" != "previous-good-archive" ]]; then
	printf 'WINDOWS_PORTABLE_BUNDLE_FAIL: failed packaging replaced the previous archive\n' >&2
	exit 1
fi

printf 'WINDOWS_PORTABLE_ATOMIC_OK: previous archive survived an injected failure\n'
