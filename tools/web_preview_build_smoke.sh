#!/usr/bin/env bash
set -Eeuo pipefail

# Regression gate for generated Web output being re-imported into the next
# Godot export. Run from any directory; the test exercises the real helper.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PCK_PATH="$ROOT_DIR/build/web/index.pck"

build_once() {
	"$ROOT_DIR/tools/web_preview.sh" build >/dev/null
	[[ -s "$PCK_PATH" ]] || {
		echo "WEB_PREVIEW_BUILD_FAIL: export did not produce index.pck" >&2
		exit 1
	}
	if strings -a "$PCK_PATH" | grep -Fq "res://build/"; then
		echo "WEB_PREVIEW_BUILD_FAIL: generated build output was embedded as a game resource" >&2
		strings -a "$PCK_PATH" | grep -F "res://build/" | sort -u >&2
		exit 1
	fi
	sha256sum "$PCK_PATH" | awk '{print $1}'
}

first_hash="$(build_once)"
second_hash="$(build_once)"
if [[ "$first_hash" != "$second_hash" ]]; then
	echo "WEB_PREVIEW_BUILD_FAIL: consecutive exports are not reproducible" >&2
	exit 1
fi

echo "WEB_PREVIEW_BUILD_OK generated_resources=excluded consecutive_hash=$first_hash"
