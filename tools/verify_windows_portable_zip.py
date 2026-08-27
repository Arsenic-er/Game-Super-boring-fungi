#!/usr/bin/env python3
from __future__ import annotations

import sys
import zipfile
from pathlib import Path


EXPECTED_ENTRIES = sorted(
    [
        "FungiMicroculture.exe",
        "FungiMicroculture.pck",
        "README-FIRST.txt",
    ]
)


class BundleValidationError(RuntimeError):
    pass


def validate_archive(archive_path: str | Path) -> None:
    path = Path(archive_path)
    if not path.is_file():
        raise BundleValidationError(f"archive not found: {path}")

    try:
        with zipfile.ZipFile(path) as archive:
            infos = archive.infolist()
            names = sorted(info.filename for info in infos)
            if names != EXPECTED_ENTRIES:
                raise BundleValidationError(
                    f"expected entries {EXPECTED_ENTRIES}, got {names}"
                )

            empty = sorted(info.filename for info in infos if info.file_size <= 0)
            if empty:
                raise BundleValidationError("empty entries: " + ", ".join(empty))

            corrupt_member = archive.testzip()
            if corrupt_member is not None:
                raise BundleValidationError(
                    f"CRC check failed for archive member: {corrupt_member}"
                )
    except (OSError, zipfile.BadZipFile, zipfile.LargeZipFile) as error:
        raise BundleValidationError(f"invalid ZIP archive: {error}") from error


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(
            f"usage: {Path(argv[0]).name} /path/to/FungiMicroculture-Windows-x64.zip",
            file=sys.stderr,
        )
        return 2

    try:
        validate_archive(argv[1])
    except BundleValidationError as error:
        print(f"WINDOWS_PORTABLE_ZIP_FAIL: {error}", file=sys.stderr)
        return 1

    print(
        "WINDOWS_PORTABLE_ZIP_OK: "
        + ", ".join(EXPECTED_ENTRIES)
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
