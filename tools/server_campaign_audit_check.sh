#!/usr/bin/env bash
# Server-only audit-checkpoint runtime and seven-language renderer verification.
set -euo pipefail
source_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_root="$(cd "$source_root/.." && pwd)"
godot="${GODOT_BIN:-$project_root/tools/godot/4.7/godot}"
display_root="${FUNGI_DISPLAY_ROOT:-$project_root/tools/xvfb}"
mode="${1:-render}"
[[ "$mode" == render || "$mode" == headless ]] || { echo 'Use render or headless' >&2; exit 2; }
[[ -x "$godot" ]] || { echo 'Godot unavailable' >&2; exit 2; }
run_dir="${FUNGI_TEST_LOG_DIR:-$project_root/test-logs}/campaign-audit-$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$run_dir/captures" "$project_root/tmp"
work="$(mktemp -d "$project_root/tmp/campaign-audit.XXXXXX")"
cleanup() {
    local resolved
    resolved="$(realpath -- "$work")"
    if [[ ! -L "$work" && "$resolved" == "$project_root/tmp/campaign-audit."* ]]; then
        rm -rf -- "$work"
    fi
}
trap cleanup EXIT
rsync -a --exclude='.git/' --exclude='.godot/' --exclude='build/' --exclude='release/' --exclude='__pycache__/' --exclude='*.log' "$source_root/" "$work/"
export HOME="$work/.home"
export XDG_DATA_HOME="$work/.xdg/data"
export XDG_CONFIG_HOME="$work/.xdg/config"
export XDG_CACHE_HOME="$work/.xdg/cache"
mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
timeout --kill-after=5 180 "$godot" --headless --editor --path "$work" --import --quit >"$run_dir/import.log" 2>&1
if [[ "$mode" == headless ]]; then
    timeout --kill-after=5 180 "$godot" --headless --audio-driver Dummy --path "$work" --script res://tests/campaign_audit_smoke.gd >"$run_dir/runtime.log" 2>&1
else
    for executable in proot Xvfb xvfb-run xkbcomp; do
        [[ -x "$display_root/usr/bin/$executable" ]] || { echo "Missing $executable" >&2; exit 2; }
    done
    command -v xauth >/dev/null
    export PATH="$display_root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="$display_root/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
    export LIBGL_ALWAYS_SOFTWARE=1 __GLX_VENDOR_LIBRARY_NAME=mesa
    export FUNGI_AUDIT_VISUAL_OUT="$run_dir/captures"
    timeout --kill-after=5 240 "$display_root/usr/bin/proot" -b "$display_root/usr/bin/xkbcomp:/usr/bin/xkbcomp" \
        "$display_root/usr/bin/xvfb-run" -a -e "$run_dir/xvfb.log" -s '-screen 0 1280x720x24 -nolisten tcp' \
        "$godot" --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy \
        --path "$work" --script res://tests/campaign_audit_smoke.gd >"$run_dir/runtime.log" 2>&1
    python3 - "$run_dir/captures" <<'PY'
import pathlib, struct, sys
root = pathlib.Path(sys.argv[1])
expected = {f"audit_{locale}_{w}x{h}.png": (w, h)
            for locale in ("zh_CN", "zh_TW", "en", "ja", "es", "de", "ru")
            for w, h in ((1280, 720), (640, 360))}
assert {p.name for p in root.glob("*.png")} == set(expected)
for name, size in expected.items():
    data = (root / name).read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n" and struct.unpack(">II", data[16:24]) == size, name
print("AUDIT_CAPTURES_OK count=14 locales=7 sizes=2")
PY
fi
if grep -Eq 'SCRIPT ERROR:|Parse Error:|CAMPAIGN_AUDIT_FAIL|Segmentation fault|CRASH' "$run_dir/import.log" "$run_dir/runtime.log"; then
    echo "CAMPAIGN_AUDIT_CHECK_FAIL logs=$run_dir" >&2
    exit 1
fi
grep 'CAMPAIGN_AUDIT_OK' "$run_dir/runtime.log"
echo "CAMPAIGN_AUDIT_CHECK_OK mode=$mode logs=$run_dir"
