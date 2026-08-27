#!/usr/bin/env python3
from __future__ import annotations

import struct
import sys
import tempfile
import warnings
import zipfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
sys.dont_write_bytecode = True

from verify_windows_portable_zip import BundleValidationError, validate_archive


EXPECTED_FILES = {
    "FungiMicroculture.exe": b"fake executable",
    "FungiMicroculture.pck": b"fake game data",
    "README-FIRST.txt": b"keep exe and pck together",
}


def write_archive(path: Path, entries: list[tuple[str, bytes]]) -> None:
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_STORED) as archive:
        for name, payload in entries:
            archive.writestr(name, payload)


def require_rejected(path: Path, label: str) -> None:
    try:
        validate_archive(path)
    except BundleValidationError:
        return
    raise AssertionError(f"validator accepted invalid archive: {label}")


def corrupt_member_payload(path: Path, member: str) -> None:
    with zipfile.ZipFile(path) as archive:
        info = archive.getinfo(member)
        filename_length = len(info.filename.encode("utf-8"))
        with path.open("r+b") as handle:
            handle.seek(info.header_offset)
            header = handle.read(30)
            extra_length = struct.unpack_from("<H", header, 28)[0]
            payload_offset = info.header_offset + 30 + filename_length + extra_length
            handle.seek(payload_offset)
            original = handle.read(1)
            handle.seek(payload_offset)
            handle.write(bytes([original[0] ^ 0xFF]))


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="fungi-zip-validator-") as temp:
        root = Path(temp)
        valid = root / "valid.zip"
        write_archive(valid, list(EXPECTED_FILES.items()))
        validate_archive(valid)

        missing = root / "missing.zip"
        write_archive(missing, list(EXPECTED_FILES.items())[:-1])
        require_rejected(missing, "missing README")

        nested = root / "nested.zip"
        write_archive(
            nested,
            [("nested/" + name, payload) for name, payload in EXPECTED_FILES.items()],
        )
        require_rejected(nested, "nested entries")

        duplicate = root / "duplicate.zip"
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            write_archive(
                duplicate,
                list(EXPECTED_FILES.items())
                + [("FungiMicroculture.pck", b"duplicate game data")],
            )
        require_rejected(duplicate, "duplicate PCK")

        corrupt = root / "corrupt.zip"
        write_archive(corrupt, list(EXPECTED_FILES.items()))
        corrupt_member_payload(corrupt, "FungiMicroculture.pck")
        require_rejected(corrupt, "CRC-corrupt PCK")

    print("WINDOWS_PORTABLE_ZIP_VALIDATOR_OK: valid and four invalid cases")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
