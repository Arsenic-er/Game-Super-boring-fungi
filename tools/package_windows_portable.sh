#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-/home/ubuntu/fungi/tools/godot/4.7/godot}"
python_bin="${PYTHON_BIN:-python3}"
output_arg="${1:-$repo_root/release/FungiMicroculture-Windows-x64.zip}"
stage_dir="$(mktemp -d "${TMPDIR:-/tmp}/fungi-windows-portable.XXXXXX")"
archive_temp=""

cleanup() {
	rm -rf "$stage_dir"
	if [[ -n "$archive_temp" ]]; then
		rm -f "$archive_temp"
	fi
}
trap cleanup EXIT

if [[ ! -x "$godot_bin" ]]; then
	printf 'WINDOWS_PORTABLE_PACKAGE_FAIL: Godot executable not found: %s\n' "$godot_bin" >&2
	exit 1
fi

if ! command -v "$python_bin" >/dev/null 2>&1; then
	printf 'WINDOWS_PORTABLE_PACKAGE_FAIL: Python executable not found: %s\n' "$python_bin" >&2
	exit 1
fi

output_dir_arg="$(dirname -- "$output_arg")"
output_name="$(basename -- "$output_arg")"
mkdir -p "$output_dir_arg"
output_dir="$(cd "$output_dir_arg" && pwd -P)"
output_path="$output_dir/$output_name"

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
archive_temp="$(mktemp "$output_dir/.${output_name}.tmp.XXXXXX")"

(
	cd "$stage_dir"
	"$python_bin" -m zipfile -c "$archive_temp" \
		FungiMicroculture.exe \
		FungiMicroculture.pck \
		README-FIRST.txt
)

"$python_bin" "$repo_root/tools/verify_windows_portable_zip.py" "$archive_temp"
chmod 0644 "$archive_temp"
mv -f "$archive_temp" "$output_path"
archive_temp=""

printf 'WINDOWS_PORTABLE_PACKAGE_OK: %s\n' "$output_path"
