#!/usr/bin/env bash
# Actual offline-review UI rendering, on the server only.
set -euo pipefail
source_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
project_root="$(dirname "$source_root")"
godot="${GODOT_BIN:-$project_root/tools/godot/4.7/godot}"
display_root="${FUNGI_DISPLAY_ROOT:-$project_root/tools/xvfb}"
log_root="${FUNGI_TEST_LOG_DIR:-$project_root/test-logs}"
mode="${1:-render}"
[[ "$mode" == render || "$mode" == headless ]] || exit 2
mkdir -p "$project_root/tmp" "$log_root"
work="$(mktemp -d "$project_root/tmp/review-layout.XXXXXX")"
run_dir="$log_root/review-layout-$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$run_dir/captures"
cleanup() {
    local resolved
    resolved="$(realpath -- "$work")"
    if [[ ! -L "$work" && "$resolved" == "$project_root/tmp/review-layout."* ]]; then
        rm -rf -- "$resolved"
    fi
}
trap cleanup EXIT
rsync -a --exclude='.git/' --exclude='.godot/' --exclude='build/' --exclude='release/' --exclude='*.log' "$source_root/" "$work/"
export HOME="$work/.home"
export XDG_DATA_HOME="$work/.xdg/data"
export XDG_CONFIG_HOME="$work/.xdg/config"
export XDG_CACHE_HOME="$work/.xdg/cache"
mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
timeout --kill-after=5 180 "$godot" --headless --editor --path "$work" --import --quit >"$run_dir/import.log" 2>&1
if [[ "$mode" == headless ]]; then
    timeout --kill-after=5 180 "$godot" --headless --audio-driver Dummy --path "$work" --script res://tests/review_slice_layout_smoke.gd >"$run_dir/render.log" 2>&1
else
    for executable in proot Xvfb xvfb-run xkbcomp; do
        [[ -x "$display_root/usr/bin/$executable" ]] || { echo "Missing render tool: $executable" >&2; exit 2; }
    done
    export PATH="$display_root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="$display_root/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
    export LIBGL_ALWAYS_SOFTWARE=1 __GLX_VENDOR_LIBRARY_NAME=mesa
    export FUNGI_REVIEW_VISUAL_OUT="$run_dir/captures"
    timeout --kill-after=5 240 "$display_root/usr/bin/proot" -b "$display_root/usr/bin/xkbcomp:/usr/bin/xkbcomp" \
        "$display_root/usr/bin/xvfb-run" -a -e "$run_dir/xvfb.log" -s '-screen 0 1280x720x24 -nolisten tcp' \
        "$godot" --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy \
        --path "$work" --script res://tests/review_slice_layout_smoke.gd >"$run_dir/render.log" 2>&1
fi
if grep -Eq '(^|[[:space:]])(SCRIPT ERROR:|ERROR:|FATAL:|CRASH:)' "$run_dir/import.log" "$run_dir/render.log"; then
    echo "REVIEW_LAYOUT_FAIL: $run_dir" >&2
    exit 1
fi
grep 'REVIEW_SLICE_LAYOUT_OK' "$run_dir/render.log"
if [[ "$mode" == render ]]; then
    python3 - "$run_dir/captures/summary.json" <<'PY'
import json, sys
from pathlib import Path
summary = Path(sys.argv[1])
data = json.loads(summary.read_text())
assert data["captures"] == 168 and data["scenes"] == 9 and data["locales"] == 7
assert len(list(summary.parent.glob("*.png"))) == 168
assert data["human_visual_review"] is False
print("REVIEW_SERVER_RENDER_OK captures=168 human_visual_review=false")
PY
fi
printf 'LOGS: %s\n' "$run_dir"
