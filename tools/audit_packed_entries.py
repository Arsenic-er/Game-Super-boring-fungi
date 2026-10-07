#!/usr/bin/env python3
"""Check actual exported PCK entry routing with disposable server-only profiles."""
import argparse
import datetime
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile

from verify_review_slices_zip import AUDIT_STAGES, MISSIONS, validate_archive


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--godot", default="/home/ubuntu/fungi/tools/godot/4.7/godot")
    parser.add_argument("--root", type=Path, default=Path("/home/ubuntu/fungi"))
    args = parser.parse_args()
    identity = validate_archive(args.archive)
    assert not identity["source_dirty"], "Release routing requires clean-source build"
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    logs = args.root / "test-logs" / ("audit-packed-" + stamp)
    logs.mkdir(parents=True, exist_ok=False)
    cases = [(stage, ["--audit-hub", "--audit-stage=" + stage, "--audit-lang=zh_CN"],
              0, "CAMPAIGN_AUDIT_READY stage=" + stage) for stage in AUDIT_STAGES]
    cases += [("review_" + mission, ["--review-mission=" + mission, "--review-lang=zh_CN"],
               0, "REVIEW_SLICE_READY mission=" + mission) for mission, _ in MISSIONS]
    cases += [("normal", [], 0, "Godot Engine")]
    invalid = [
        ["--audit-stage=early_choice"], ["--audit-hub", "--audit-stage=../../save"],
        ["--audit-hub", "--audit-stage=bad"], ["--audit-hub", "--audit-hub"],
        ["--audit-hub", "--audit-stage=early_choice", "--audit-stage=early_one"],
        ["--audit-hub", "--audit-lang=bad"], ["--audit-hub", "--audit-unknown"],
        ["--audit-hub=1"], ["--audit-hub", "--review-mission=first_supply"],
        ["--audit-hub", "--audit-lang=en", "--audit-lang=zh_CN"],
        ["--audit-hub", "--review-unknown"], ["--audit-stage"],
    ]
    cases += [("invalid_" + str(i), flags, 2, "CAMPAIGN_AUDIT_INVALID")
              for i, flags in enumerate(invalid)]
    summary = {"build": identity, "native_windows": False, "results": []}
    (args.root / "tmp").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="audit-packed.", dir=args.root / "tmp") as temp:
        work = Path(temp)
        pack = work / "FungiMicroculture.pck"
        with zipfile.ZipFile(args.archive) as archive:
            pack.write_bytes(archive.read("FungiMicroculture.pck"))
        for name, flags, code, marker in cases:
            profile = work / name
            env = dict(os.environ)
            for variable, subdirectory in (("HOME", "home"), ("XDG_DATA_HOME", "data"),
                                           ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")):
                path = profile / subdirectory
                path.mkdir(parents=True)
                env[variable] = str(path)
            command = [args.godot, "--main-pack", str(pack), "--headless", "--audio-driver",
                       "Dummy", "--quit-after", "3", "--", *flags]
            result = subprocess.run(command, cwd=work, env=env, text=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=45)
            (logs / (name + ".log")).write_text(result.stdout, encoding="utf-8")
            assert result.returncode == code and marker in result.stdout, (name, result.returncode, result.stdout[-1500:])
            assert not re.search(r"SCRIPT ERROR:|Parse Error:|Segmentation fault|CRASH", result.stdout), name
            if name.startswith("invalid_"):
                assert not list(profile.rglob("*.json")), "Rejected arguments created profile data"
            elif name != "normal":
                assert not list(profile.rglob("save*.json")), "Entry auto-created or loaded a save"
            summary["results"].append({"case": name, "exit": code,
                                       "exit_object_warning": "ObjectDB instances leaked" in result.stdout})
    summary["ok"] = True
    (logs / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print("AUDIT_PACKED_OK cases=" + str(len(cases)) + " logs=" + str(logs))


if __name__ == "__main__":
    main()
