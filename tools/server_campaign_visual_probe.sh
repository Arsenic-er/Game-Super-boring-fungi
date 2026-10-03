#!/usr/bin/env bash
# Server-only OpenGL capture; not human-input or balance QA.
set -euo pipefail
source_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_root="$(cd "$source_root/.." && pwd)"
godot="${GODOT_BIN:-$project_root/tools/godot/4.7/godot}"
display_root="${FUNGI_DISPLAY_ROOT:-$project_root/tools/xvfb}"
log_root="${FUNGI_TEST_LOG_DIR:-$project_root/test-logs}"
mode="${FUNGI_VISUAL_MODE:-render}"
[[ "$mode" == render || "$mode" == validate-only ]] || { echo "Invalid FUNGI_VISUAL_MODE" >&2; exit 2; }
for executable in "$godot" "$display_root/usr/bin/proot" "$display_root/usr/bin/Xvfb" "$display_root/usr/bin/xvfb-run" "$display_root/usr/bin/xkbcomp"; do
    [[ -x "$executable" ]] || { echo "Missing render tool: $executable" >&2; exit 2; }
done
command -v xauth >/dev/null
run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
run_dir="$log_root/campaign-visual-$run_id"
mkdir -p "$run_dir/captures" "$project_root/tmp"
work="$(mktemp -d "$project_root/tmp/campaign-visual-XXXXXX")"
cleanup() {
    local resolved
    resolved="$(realpath -- "$work")"
    if [[ ! -L "$work" && "$resolved" == "$project_root/tmp/campaign-visual-"* ]]; then
        rm -rf -- "$work"
    fi
}
trap cleanup EXIT
rsync -a --exclude='.git/' --exclude='.godot/' --exclude='build/' --exclude='release/' --exclude='*.log' "$source_root/" "$work/"
export HOME="$work/.home"
export XDG_DATA_HOME="$work/.xdg/data"
export XDG_CONFIG_HOME="$work/.xdg/config"
export XDG_CACHE_HOME="$work/.xdg/cache"
export FUNGI_VISUAL_OUT="$run_dir/captures"
mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
timeout --kill-after=5 180 "$godot" --headless --editor --path "$work" --import --quit >"$run_dir/import.log" 2>&1
export PATH="$display_root/usr/bin:$PATH"
export LD_LIBRARY_PATH="$display_root/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
export LIBGL_ALWAYS_SOFTWARE=1
export __GLX_VENDOR_LIBRARY_NAME=mesa
if [[ "$mode" == validate-only ]]; then
    timeout --kill-after=5 300 "$godot" --headless --audio-driver Dummy \
        --path "$work" --scene res://scenes/CampaignVisualProbe.tscn -- --validate-only >"$run_dir/render.log" 2>&1
else
    timeout --kill-after=5 300 "$display_root/usr/bin/proot" \
    -b "$display_root/usr/bin/xkbcomp:/usr/bin/xkbcomp" \
    "$display_root/usr/bin/xvfb-run" -a -e "$run_dir/xvfb.log" \
    -s '-screen 0 1280x720x24 -nolisten tcp' \
    "$godot" --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy \
    --path "$work" --scene res://scenes/CampaignVisualProbe.tscn >"$run_dir/render.log" 2>&1
fi
if grep -Eq '(^|[[:space:]])(SCRIPT ERROR:|ERROR:|FATAL:|CRASH:)' "$run_dir/import.log" "$run_dir/render.log"; then
    echo "CAMPAIGN_SERVER_RENDER_FAIL: inspect $run_dir" >&2
    exit 1
fi
python3 - "$run_dir/captures" <<'PY'
import json
from pathlib import Path
import struct
import sys
root = Path(sys.argv[1])
manifest = json.loads((root / "campaign-capture-manifest.json").read_text())
assert manifest["ok"] and manifest["mode"] in ("render", "validate-only"), manifest.get("failure")
captures = manifest["captures"]
assert captures, "No screenshots"
locales = {"zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"}
assert {c["locale"] for c in captures if c["label"].startswith("compact_progress_")} == locales
assert {c["locale"] for c in captures if c["label"].startswith("compact_hud_")} == locales
for phase in ("home", "mission"):
    for width in (640, 1280):
        group = [c for c in captures if c["label"].startswith("developer_%s_%d_" % (phase, width))]
        assert {c["locale"] for c in group} == locales
        for capture in group:
            actions = {a["id"]: a["disabled_reason"] for a in capture["developer_actions"]}
            assert len(actions) == 6
            assert actions["campaign_start"] == ("campaign_in_mission" if phase == "mission" else "")
            assert actions["campaign_return"] == ("" if phase == "mission" else "campaign_not_in_mission")
new_missions = ("first_contact", "substrate_race", "lost_network", "two_fronts", "toxic_frontier", "boundary_counterattack", "stable_colony")
for mission in new_missions:
    phases = ("initial", "wave") if mission in ("first_contact", "two_fronts", "stable_colony") else ("initial",)
    for phase in phases:
        for surface in ("hud", "panel", "goals"):
            for width in (640, 1280):
                prefix = "chapter_%s_%s_%s_%d_" % (mission, phase, surface, width)
                group = [c for c in captures if c["label"].startswith(prefix)]
                assert {c["locale"] for c in group} == locales, prefix
                assert all(c["world_scene_id"] == mission for c in group), prefix
                if phase == "initial" and mission in ("first_contact", "two_fronts", "stable_colony"):
                    assert all(c["phase_action"] == "trial_start_wave" for c in group), prefix
for prefix in ("chapter_branches", "chapter_complete") + tuple("chapter_home_page%d" % page for page in range(1, 6)):
    for width in (640, 1280):
        group = [c for c in captures if c["label"].startswith("%s_%d_" % (prefix, width))]
        assert {c["locale"] for c in group} == locales, (prefix, width)
for capture in captures:
    assert capture["layout"]["ok"], capture["label"]
    if manifest["mode"] == "validate-only":
        assert not capture["rendered"]
        continue
    image = root / (capture["label"] + ".png")
    with image.open("rb") as stream:
        header = stream.read(24)
    assert header[:8] == b"\x89PNG\r\n\x1a\n", image
    size = list(struct.unpack(">II", header[16:24]))
    assert capture["rendered"] and size == capture["pixels"] == capture["viewport"], capture["label"]
print("CAMPAIGN_SERVER_PROBE_OK mode=%s captures=%d locales=7 missions=9 sizes=1280x720,640x360" % (manifest["mode"], len(captures)))
print("NOT_HUMAN_VISUAL_REVIEW: programmatic layout/click checks; rendered PNGs, if any, remain on server.")
PY
echo "LOGS: $run_dir"
