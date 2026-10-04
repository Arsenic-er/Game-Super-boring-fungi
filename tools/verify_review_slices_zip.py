#!/usr/bin/env python3
"""Strict offline-review ZIP validator. No extraction, network, or third-party modules."""
from __future__ import annotations
import hashlib
import json
import re
import stat
import struct
import sys
import zipfile
from pathlib import Path, PurePosixPath

MISSIONS = (
    ("first_supply", "FirstSupply"), ("remote_pantry", "RemotePantry"),
    ("first_contact", "FirstContact"), ("substrate_race", "SubstrateRace"),
    ("lost_network", "LostNetwork"), ("two_fronts", "TwoFronts"),
    ("toxic_frontier", "ToxicFrontier"), ("boundary_counterattack", "BoundaryCounterattack"),
    ("stable_colony", "StableColony"),
)
TITLES = ("第一条补给线", "远端粮仓", "第一次接触", "培养基争夺", "失联网络",
          "双线压力", "污染前缘", "边界反攻", "稳定菌落")
LAUNCHERS = {f"{index:02d} {title}.cmd": mission[0]
             for index, (mission, title) in enumerate(zip(MISSIONS, TITLES), 1)}
ROOT_FILES = {
    "FungiMicroculture.exe", "FungiMicroculture.pck", "README-FIRST.txt", "START-HERE.txt",
    "build-info.json",
} | set(LAUNCHERS)
IDENTITY_FIELDS = ("build_id", "build_utc", "source_commit", "source_dirty", "source_sha256",
                   "mission_ids", "missions", "profile", "save_root")

class BundleValidationError(RuntimeError):
    pass

def require(condition: bool, message: str) -> None:
    if not condition:
        raise BundleValidationError(message)

def safe_member(name: str) -> bool:
    path = PurePosixPath(name)
    return (name != "" and "\\" not in name and ":" not in name and not path.is_absolute()
            and all(part not in ("", ".", "..") for part in name.split("/")))

def validate_pe(data: bytes) -> None:
    require(len(data) >= 1024 and data[:2] == b"MZ", "EXE missing DOS header")
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    require(pe + 24 < len(data) and data[pe:pe + 4] == b"PE\0\0", "invalid PE header")
    machine, sections = struct.unpack_from("<HH", data, pe + 4)
    optional_size = struct.unpack_from("<H", data, pe + 20)[0]
    optional = pe + 24
    require(machine == 0x8664 and struct.unpack_from("<H", data, optional)[0] == 0x20B, "expected Windows x64 PE32+")
    require(struct.unpack_from("<H", data, optional + 68)[0] == 2, "EXE must use GUI subsystem")
    table = optional + optional_size
    require(0 < sections < 128 and table + sections * 40 <= len(data), "invalid PE section table")
    pck_seen = False
    for index in range(sections):
        at = table + index * 40
        name = data[at:at + 8].rstrip(b"\0")
        virtual_size = struct.unpack_from("<I", data, at + 8)[0]
        raw_size, raw_offset = struct.unpack_from("<II", data, at + 16)
        if name == b"pck":
            pck_seen = True
            require(virtual_size <= 8 and raw_size <= 512, "EXE contains embedded PCK section")
            require(raw_offset + raw_size <= len(data) and not any(data[raw_offset:raw_offset + raw_size]),
                    "EXE PCK locator is populated instead of an empty split-pack placeholder")
        require(raw_size == 0 or raw_offset + raw_size <= len(data), "PE section outside EXE")
    require(pck_seen, "Godot PCK placeholder section missing")
    require(data[-4:] != b"GDPC", "EXE contains appended PCK footer")

def pck_entries(data: bytes) -> dict[str, bytes]:
    require(len(data) >= 116 and data[:4] == b"GDPC", "invalid PCK magic/header")
    version, engine_major, engine_minor, _patch, flags = struct.unpack_from("<IIIII", data, 4)
    require(version == 4 and engine_major == 4 and engine_minor == 7, "expected Godot 4.7 PCK v4")
    require(flags == 2, "unexpected encrypted or absolute-offset PCK flags")
    file_base, directory_offset = struct.unpack_from("<QQ", data, 24)
    require(112 <= file_base < directory_offset < len(data), "invalid PCK file/directory offsets")
    count = struct.unpack_from("<I", data, directory_offset)[0]
    require(100 <= count <= 5000, "unexpected PCK entry count")
    position = directory_offset + 4
    entries: dict[str, bytes] = {}
    for _ in range(count):
        require(position + 4 <= len(data), "truncated PCK index")
        name_size = struct.unpack_from("<I", data, position)[0]
        position += 4
        require(0 < name_size < 4096 and position + name_size + 36 <= len(data), "invalid PCK name length")
        try:
            name = data[position:position + name_size].rstrip(b"\0").decode("utf-8")
        except UnicodeDecodeError as error:
            raise BundleValidationError("non-UTF8 PCK filename") from error
        position += name_size
        offset, size, md5, entry_flags = struct.unpack_from("<QQ16sI", data, position)
        position += 36
        require(safe_member(name) and name not in entries, "unsafe or duplicate PCK path: " + name)
        require(entry_flags == 0, "encrypted/deleted PCK entry: " + name)
        start = file_base + offset
        require(file_base <= start <= directory_offset and start + size <= directory_offset, "PCK payload outside data section: " + name)
        payload = data[start:start + size]
        require(hashlib.md5(payload).digest() == md5, "PCK MD5 mismatch: " + name)
        require(not name.startswith(("tests/", "tests-upload/", "tools/", "design/", "packaging/")), "development-only PCK resource: " + name)
        require("CampaignVisualProbe" not in name, "visual probe exported into review game")
        entries[name] = payload
    require(position == len(data), "unaccounted data after PCK directory")
    return entries

def require_remapped(entries: dict[str, bytes], original: str) -> str:
    remap_name = original + ".remap"
    require(remap_name in entries, "missing scene/script remap: " + remap_name)
    text = entries[remap_name].decode("utf-8")
    match = re.search(r'^path="res://([^"]+)"', text, re.M)
    require(match is not None, "invalid remap target: " + original)
    destination = match.group(1)
    require(destination in entries and len(entries[destination]) > 40, "missing compiled remap resource: " + destination)
    return destination

def validate_archive(path: str | Path, update: bool = False) -> dict:
    try:
        with zipfile.ZipFile(path) as archive:
            infos = archive.infolist()
            names = [info.filename for info in infos]
            require(len(names) == len(set(names)), "duplicate ZIP entries")
            require(all(safe_member(name) for name in names), "unsafe ZIP member path")
            require(all(not item.is_dir() and item.file_size > 0 for item in infos), "empty file or directory ZIP entry")
            require(all(not stat.S_ISLNK(item.external_attr >> 16) for item in infos), "ZIP symlink forbidden")
            require(sum(item.file_size for item in infos) < 300_000_000, "review bundle unexpectedly large")
            require(archive.testzip() is None, "ZIP CRC failure")
            expected_roots = (ROOT_FILES - {"FungiMicroculture.exe"} | {"review-update-info.json"}) if update else ROOT_FILES
            actual_roots = {name for name in names if "/" not in name}
            require(actual_roots == expected_roots, "root ZIP files differ from exact manifest")
            doc_names = {name for name in names if name.startswith("review-docs/")}
            require(all("/" not in name[len("review-docs/"):] and name.endswith((".md", ".html")) for name in doc_names), "unexpected review document path")
            require(set(names) == actual_roots | doc_names, "unrecognized top-level ZIP content")
            markdown = {name for name in doc_names if name.endswith(".md")}
            expected_markdown = {"review-docs/README.md", *("review-docs/" + row[0] + ".md" for row in MISSIONS)}
            require(markdown == expected_markdown and "review-docs/index.html" in doc_names, "missing or extra named cards/overview/index")
            require(doc_names == markdown | {name[:-3] + ".html" for name in markdown} | {"review-docs/index.html"}, "missing or extra HTML counterparts")
            info = json.loads(archive.read("build-info.json"))
            require(info["format_version"] == 1 and info["layout"] == "one-exe-and-adjacent-pck", "incorrect build manifest format/layout")
            require(re.fullmatch(r"[0-9a-f]{40}", info["source_commit"]) is not None, "invalid source commit")
            require(re.fullmatch(r"[0-9a-f]{64}", info["source_sha256"]) is not None, "invalid source SHA-256")
            require(type(info["source_dirty"]) is bool, "dirty status must be explicit boolean")
            require(info["mission_ids"] == [row[0] for row in MISSIONS], "manifest must have nine exact ordered mission IDs")
            require([row["id"] for row in info["missions"]] == info["mission_ids"], "mission detail list mismatch")
            require([row["title_zh"] for row in info["missions"]] == list(TITLES), "Chinese mission titles mismatch")
            require([row["scene"] for row in info["missions"]] == ["res://scenes/missions/" + row[1] + ".tscn" for row in MISSIONS], "mission scene paths mismatch")
            for filename, mission_id in LAUNCHERS.items():
                launcher = archive.read(filename)
                expected = ('@echo off\r\nstart "" "%~dp0FungiMicroculture.exe" -- --review-mission='
                            + mission_id + ' --review-lang=zh_CN\r\n').encode("ascii")
                require(launcher == expected, "launcher must contain exact ASCII command, relative EXE and unique mission: " + filename)
                require(not launcher.startswith(b"\xef\xbb\xbf") and all(byte < 128 for byte in launcher), "launcher must be ASCII without BOM")
            require(info["profile"] == "paid-baseline", "unexpected review profile")
            expected_files = set(names) - {"build-info.json", "review-update-info.json"}
            if update:
                expected_files.add("FungiMicroculture.exe")
            require(set(info["files"]) == expected_files, "exact file SHA manifest mismatch")
            for name, meta in info["files"].items():
                require(re.fullmatch(r"[0-9a-f]{64}", meta["sha256"]) is not None and meta["bytes"] > 0, "bad SHA manifest entry: " + name)
                if update and name == "FungiMicroculture.exe":
                    continue
                payload = archive.read(name)
                require(len(payload) == meta["bytes"] and hashlib.sha256(payload).hexdigest() == meta["sha256"], "ZIP file hash/size mismatch: " + name)
            if update:
                delta = json.loads(archive.read("review-update-info.json"))
                require(delta["kind"] == "requires-existing-exact-engine", "update must declare non-standalone status")
                require(delta["requires_exact_exe_sha256"] == info["files"]["FungiMicroculture.exe"]["sha256"], "required engine SHA differs from manifest")
            else:
                validate_pe(archive.read("FungiMicroculture.exe"))
            entries = pck_entries(archive.read("FungiMicroculture.pck"))
            require_remapped(entries, "scenes/ReviewSlice.tscn")
            require_remapped(entries, "scripts/review_slice.gd")
            require_remapped(entries, "scripts/review_slice_localization.gd")
            require_remapped(entries, "scripts/review_objectives.gd")
            require_remapped(entries, "scripts/review_campaign_controller.gd")
            for mission_id, scene in MISSIONS:
                require_remapped(entries, "scenes/missions/" + scene + ".tscn")
                require(any(mission_id in name for name in markdown), "missing audit card for: " + mission_id)
            # Bind the actual compiled review script referenced by the review scene.
            compiled_scene = entries[require_remapped(entries, "scenes/ReviewSlice.tscn")]
            require(len(compiled_scene) > 80, "review scene is only a placeholder")
            require("review_build_info.json" in entries, "embedded audit build identity missing")
            embedded = json.loads(entries["review_build_info.json"])
            require(all(embedded[key] == info[key] for key in IDENTITY_FIELDS), "embedded/source build identity mismatch")
            return {"build_id": info["build_id"], "source_commit": info["source_commit"],
                    "source_dirty": info["source_dirty"], "zip_entries": len(names), "pck_entries": len(entries),
                    "archive_sha256": hashlib.sha256(Path(path).read_bytes()).hexdigest(), "update": update, "ascii_launchers": len(LAUNCHERS)}
    except BundleValidationError:
        raise
    except (OSError, ValueError, KeyError, TypeError, struct.error, zipfile.BadZipFile, UnicodeError) as error:
        raise BundleValidationError(str(error)) from error

def main(argv: list[str]) -> int:
    args = argv[1:]; update = False
    if args and args[0] == "--update":
        update = True; args = args[1:]
    if len(args) != 1:
        print("usage: verify_review_slices_zip.py [--update] archive.zip", file=sys.stderr)
        return 2
    try:
        result = validate_archive(args[0], update)
    except BundleValidationError as error:
        print("REVIEW_ZIP_FAIL: " + str(error), file=sys.stderr)
        return 1
    print("REVIEW_ZIP_OK: " + json.dumps(result, sort_keys=True))
    return 0

if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
