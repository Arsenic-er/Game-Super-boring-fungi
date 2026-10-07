#!/usr/bin/env bash
# Build offline Chapter 1 audit slices without touching the normal project/export.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-/home/ubuntu/fungi/tools/godot/4.7/godot}"
python_bin="${PYTHON_BIN:-python3}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/home/ubuntu/fungi/tools/godot-data}"
output_arg="${1:-$repo_root/release/FungiChapter1-Review-Windows-x64.zip}"
parent="$(realpath -m "$repo_root/../tmp")"
mkdir -p "$parent"
stage="$(mktemp -d "$parent/review-package.XXXXXX")"
archive_temp=""
cleanup() {
  local resolved
  resolved="$(realpath -m "$stage")"
  [[ "$resolved" == "$parent"/review-package.* && "$resolved" != "$parent" ]] || return 1
  rm -rf -- "$resolved"
  [[ -z "$archive_temp" ]] || rm -f -- "$archive_temp"
}
trap cleanup EXIT
[[ -x "$godot_bin" ]] || { printf 'REVIEW_PACKAGE_FAIL: Godot unavailable\n' >&2; exit 1; }
[[ -f "$repo_root/scenes/ReviewSlice.tscn" && -d "$repo_root/docs/review-slices" ]] || {
  printf 'REVIEW_PACKAGE_FAIL: review scene or audit cards not ready\n' >&2; exit 1;
}
mkdir -p "$(dirname "$output_arg")"
output="$(realpath -m "$output_arg")"
mkdir -p "$stage/project" "$stage/bundle"
"$python_bin" - "$repo_root" "$stage" <<'PY'
import datetime, hashlib, json, os, pathlib, shutil, subprocess, sys
repo, stage = map(pathlib.Path, sys.argv[1:])
files = subprocess.check_output(["git", "ls-files", "-co", "--exclude-standard", "-z"], cwd=repo).split(b"\0")
digest = hashlib.sha256()
for raw in sorted(set(files)):
    if not raw:
        continue
    name = os.fsdecode(raw)
    if name.split("/")[0] in {".git", ".godot", "build", "release"}:
        continue
    source = repo / name
    if source.is_symlink():
        raise SystemExit(f"REVIEW_PACKAGE_FAIL: source symlink: {name}")
    if not source.is_file():
        continue
    payload = source.read_bytes()
    digest.update(name.encode("utf-8") + b"\0" + hashlib.sha256(payload).digest())
    target = stage / "project" / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(payload)
source_hash = digest.hexdigest()
now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
dirty = bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=repo))
specs = [
 ("first_supply", "第一条补给线", "FirstSupply", "expedition"),
 ("remote_pantry", "远端粮仓", "RemotePantry", "expedition"),
 ("first_contact", "第一次接触", "FirstContact", "nest_challenge"),
 ("substrate_race", "培养基争夺", "SubstrateRace", "expedition"),
 ("lost_network", "失联网络", "LostNetwork", "expedition"),
 ("two_fronts", "双线压力", "TwoFronts", "nest_challenge"),
 ("toxic_frontier", "污染前缘", "ToxicFrontier", "expedition"),
 ("boundary_counterattack", "边界反攻", "BoundaryCounterattack", "expedition"),
 ("stable_colony", "稳定菌落", "StableColony", "nest_challenge"),
]
info = {
 "campaign_audit": {"stage_ids": ["early_choice", "early_one", "first_contact_ready", "nest_upgrade_ready", "advanced_choice", "two_fronts_ready", "finale_ready", "chapter_complete"],
                    "save_root": "user://campaign-audit-v1/<stage>/", "synthetic_fixture": True, "normal_costs": True},
 "format_version": 1,
 "build_id": "chapter1-review-" + now.replace("-", "").replace(":", "") + "-" + source_hash[:12],
 "build_utc": now, "source_commit": commit, "source_dirty": dirty, "source_sha256": source_hash,
 "profile": "paid-baseline", "save_root": "user://review-v1/<mission_id>/",
 "mission_ids": [row[0] for row in specs],
 "missions": [{"id": i, "title_zh": title, "scene": "res://scenes/missions/" + scene + ".tscn", "kind": kind}
              for i, title, scene, kind in specs],
}
(stage / "project" / "review_build_info.json").write_text(json.dumps(info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(stage / "identity.json").write_text(json.dumps(info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
# JSON metadata must be exported as raw data, not silently omitted as non-resource.
presets = stage / "project" / "export_presets.cfg"
presets.write_text(presets.read_text().replace('include_filter=""', 'include_filter="review_build_info.json"'), encoding="utf-8")
PY
log_dir="$repo_root/../test-logs/review-package-$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$log_dir"
timeout --kill-after=5s 180s "$godot_bin" --headless --path "$stage/project" --editor --import >"$log_dir/import.log" 2>&1 || {
  tail -60 "$log_dir/import.log" >&2; exit 1;
}
timeout --kill-after=5s 240s "$godot_bin" --headless --path "$stage/project" --export-release "Windows Desktop" "$stage/bundle/FungiMicroculture.exe" >"$log_dir/export.log" 2>&1 || {
  tail -60 "$log_dir/export.log" >&2; exit 1;
}
"$python_bin" - "$stage" <<'PY'
import hashlib, html, json, pathlib, shutil, sys
stage = pathlib.Path(sys.argv[1]); bundle = stage / "bundle"; project = stage / "project"
# Do not include Godot's optional console wrapper or export logs.
allowed_engine = {"FungiMicroculture.exe", "FungiMicroculture.pck"}
for path in bundle.iterdir():
    if path.name not in allowed_engine:
        path.unlink()
for name in ["README-FIRST.txt", "START-HERE.txt"]:
    shutil.copy2(project / "packaging" / "review" / name, bundle / name)
docs = project / "docs" / "review-slices"
cards = sorted(docs.glob("*.md"))
identity = json.loads((stage / "identity.json").read_text())
for number, mission in enumerate(identity["missions"], 1):
    name = f'{number:02d} {mission["title_zh"]}.cmd'
    command = '@echo off\r\nstart "" "%~dp0FungiMicroculture.exe" -- --review-mission=' + mission["id"] + ' --review-lang=zh_CN\r\n'
    # Chinese filename, ASCII-only command text: no code-page switch, COM, or PowerShell.
    (bundle / name).write_bytes(command.encode("ascii"))
(bundle / "00 主巢分支审查.cmd").write_bytes(
    b'@echo off\r\nstart "" "%~dp0FungiMicroculture.exe" -- --audit-hub --audit-lang=zh_CN\r\n')
if {p.stem for p in cards} != {"README", *identity["mission_ids"]}:
    raise SystemExit("REVIEW_PACKAGE_FAIL: require exactly 9 named audit cards and README.md")
target_docs = bundle / "review-docs"; target_docs.mkdir()
titles = {"README": "开始审查与统一规则", **{m["id"]: m["title_zh"] for m in identity["missions"]}}
for card in cards:
    shutil.copy2(card, target_docs / card.name)
    # Self-contained static text, no script, iframe, stylesheet, CDN, or network.
    content = card.read_text(encoding="utf-8")
    page = '<!doctype html><meta charset="utf-8"><title>' + html.escape(card.stem) + '</title>'
    page += '<style>body{max-width:1000px;margin:32px auto;padding:0 24px;background:#07121b;color:#d7f7e4;font:18px/1.65 sans-serif}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:inherit}a{color:#a0e4c7}</style>'
    page += '<p><a href="index.html">返回审查卡目录</a></p><pre>' + html.escape(content) + '</pre>'
    (target_docs / (card.stem + ".html")).write_text(page, encoding="utf-8")
links = ['<li><a href="' + key + '.html">' + html.escape(titles[key]) + '</a></li>' for key in ["README", *identity["mission_ids"]]]
index = '<!doctype html><meta charset="utf-8"><title>第一章审查卡</title><h1>第一章独立游戏切片</h1><p>这些只是离线说明，不在浏览器运行游戏。双击“00 主巢分支审查.cmd”可以直接进入任一进度节点，F8 随时切换；01–09 仍是各关的独立试玩。无需重打前置关卡。</p><ul>' + "".join(links) + "</ul>"
(target_docs / "index.html").write_text(index, encoding="utf-8")
info = json.loads((stage / "identity.json").read_text())
info["layout"] = "one-exe-and-adjacent-pck"
info["files"] = {p.relative_to(bundle).as_posix(): {"sha256": hashlib.sha256(p.read_bytes()).hexdigest(), "bytes": p.stat().st_size}
                 for p in sorted(bundle.rglob("*")) if p.is_file()}
(bundle / "build-info.json").write_text(json.dumps(info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
archive_temp="$(mktemp "$(dirname "$output")/.review-full.XXXXXX")"
"$python_bin" - "$stage/bundle" "$archive_temp" <<'PY'
import pathlib, sys, zipfile
source = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(sys.argv[2], "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for path in sorted(source.rglob("*")):
        if path.is_file():
            archive.write(path, path.relative_to(source).as_posix())
PY
"$python_bin" "$repo_root/tools/verify_review_slices_zip.py" "$archive_temp" | tee "$log_dir/verification.txt"
chmod 0644 "$archive_temp"
mv -f -- "$archive_temp" "$output"; archive_temp=""
printf 'REVIEW_PACKAGE_OK: %s\n' "$output"
sha256sum "$output"
if [[ -n "${FUNGI_REVIEW_REUSE_EXE_SHA256:-}" ]]; then
  if [[ "$(sha256sum "$stage/bundle/FungiMicroculture.exe" | cut -d' ' -f1)" == "$FUNGI_REVIEW_REUSE_EXE_SHA256" ]]; then
    update="$(dirname "$output")/FungiChapter1-Review-Update.zip"
    archive_temp="$(mktemp "$(dirname "$output")/.review-update.XXXXXX")"
    "$python_bin" - "$stage/bundle" "$archive_temp" "$FUNGI_REVIEW_REUSE_EXE_SHA256" <<'PY'
import json, pathlib, sys, zipfile
source = pathlib.Path(sys.argv[1])
update = {"format_version": 1, "kind": "requires-existing-exact-engine", "requires_exact_exe_sha256": sys.argv[3],
          "warning": "Not a standalone game. Verify the existing FungiMicroculture.exe SHA-256 before applying."}
with zipfile.ZipFile(sys.argv[2], "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for path in sorted(source.rglob("*")):
        if path.is_file() and path.name != "FungiMicroculture.exe":
            archive.write(path, path.relative_to(source).as_posix())
    archive.writestr("review-update-info.json", json.dumps(update, indent=2) + "\n")
PY
    "$python_bin" "$repo_root/tools/verify_review_slices_zip.py" --update "$archive_temp" | tee "$log_dir/update-verification.txt"
    chmod 0644 "$archive_temp"; mv -f -- "$archive_temp" "$update"; archive_temp=""
    printf 'REVIEW_UPDATE_OK: %s\n' "$update"; sha256sum "$update"
  else
    printf 'REVIEW_UPDATE_SKIPPED: current EXE differs from requested engine SHA-256; use full bundle.\n'
  fi
fi
printf 'REVIEW_PACKAGE_LOGS: %s\n' "$log_dir"
