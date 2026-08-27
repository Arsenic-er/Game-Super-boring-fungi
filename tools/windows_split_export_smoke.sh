#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-/home/ubuntu/fungi/tools/godot/4.7/godot}"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/fungi-windows-split-export.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

export_base="$temp_dir/FungiMicroculture"
export_exe="$export_base.exe"
export_pck="$export_base.pck"
export_log="$temp_dir/export.log"

if [[ ! -x "$godot_bin" ]]; then
	printf 'WINDOWS_SPLIT_EXPORT_FAIL: Godot executable not found: %s\n' "$godot_bin" >&2
	exit 1
fi

if ! "$godot_bin" --headless --path "$repo_root" --export-release "Windows Desktop" "$export_exe" >"$export_log" 2>&1; then
	cat "$export_log" >&2
	printf 'WINDOWS_SPLIT_EXPORT_FAIL: Godot Windows export failed\n' >&2
	exit 1
fi

if [[ ! -s "$export_exe" ]]; then
	cat "$export_log" >&2
	printf 'WINDOWS_SPLIT_EXPORT_FAIL: missing exported executable: %s\n' "$export_exe" >&2
	exit 1
fi

if [[ ! -s "$export_pck" ]]; then
	cat "$export_log" >&2
	printf 'WINDOWS_SPLIT_EXPORT_FAIL: Windows export must place game data in a separate FungiMicroculture.pck file\n' >&2
	exit 1
fi

exe_size="$(stat -c '%s' "$export_exe")"
pck_size="$(stat -c '%s' "$export_pck")"
printf 'WINDOWS_SPLIT_EXPORT_OK: exe=%s bytes pck=%s bytes\n' "$exe_size" "$pck_size"
