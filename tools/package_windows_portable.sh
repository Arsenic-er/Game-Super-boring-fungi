#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-/home/ubuntu/fungi/tools/godot/4.7/godot}"
output_arg="${1:-$repo_root/release/FungiMicroculture-Windows-x64.zip}"
output_path="$(realpath -m "$output_arg")"
stage_dir="$(mktemp -d "${TMPDIR:-/tmp}/fungi-windows-portable.XXXXXX")"
trap 'rm -rf "$stage_dir"' EXIT

if [[ ! -x "$godot_bin" ]]; then
	printf 'WINDOWS_PORTABLE_PACKAGE_FAIL: Godot executable not found: %s\n' "$godot_bin" >&2
	exit 1
fi

mkdir -p "$(dirname "$output_path")"

export_exe="$stage_dir/FungiMicroculture.exe"
export_pck="$stage_dir/FungiMicroculture.pck"
export_log="$stage_dir/export.log"
readme_source="$repo_root/packaging/README-FIRST.txt"

if ! "$godot_bin" --headless --path "$repo_root" --export-release "Windows Desktop" "$export_exe" >"$export_log" 2>&1; then
	cat "$export_log" >&2
	printf 'WINDOWS_PORTABLE_PACKAGE_FAIL: Godot Windows export failed\n' >&2
	exit 1
fi

for required_file in "$export_exe" "$export_pck" "$readme_source"; do
	if [[ ! -s "$required_file" ]]; then
		printf 'WINDOWS_PORTABLE_PACKAGE_FAIL: missing required file: %s\n' "$required_file" >&2
		exit 1
	fi
done

cp "$readme_source" "$stage_dir/README-FIRST.txt"
rm -f "$output_path"

(
	cd "$stage_dir"
	python3 -m zipfile -c "$output_path" \
		FungiMicroculture.exe \
		FungiMicroculture.pck \
		README-FIRST.txt
)

printf 'WINDOWS_PORTABLE_PACKAGE_OK: %s\n' "$output_path"
