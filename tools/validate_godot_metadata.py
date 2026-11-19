"""Check Godot source-side metadata without running the engine."""

import argparse
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent
UID_SOURCES = {".gd", ".gdshader", ".gdshaderinc"}
IMPORT_CANDIDATES = {
    ".bmp", ".dds", ".exr", ".hdr", ".jpeg", ".jpg", ".ktx", ".png",
    ".svg", ".tga", ".webp", ".wav", ".ogg", ".mp3", ".ttf", ".otf",
    ".woff", ".woff2", ".glb", ".gltf", ".obj", ".fbx", ".blend", ".dae",
}


def git(*args):
    return subprocess.check_output(
        ["git", "-C", str(ROOT), *args],
        env={**os.environ, "GIT_NO_LAZY_FETCH": "1"},
    )


def indexed_files():
    files = {}
    for entry in git("ls-files", "--stage", "-z").split(b"\0"):
        if not entry:
            continue
        metadata, name = entry.split(b"\t", 1)
        mode, oid, stage = metadata.split()
        path = name.decode("utf-8", errors="surrogateescape")
        if stage != b"0":
            raise ValueError(f"unmerged Git index entry {path!r}")
        if mode in {b"100644", b"100755"}:
            files[path] = oid.decode("ascii")
    return files


def is_working_file(name):
    path = ROOT
    try:
        for part in PurePosixPath(name).parts:
            path /= part
            info = path.lstat()
            if stat.S_ISLNK(info.st_mode) or (
                getattr(info, "st_file_attributes", 0) & stat.FILE_ATTRIBUTE_REPARSE_POINT
            ):
                return False
    except (FileNotFoundError, NotADirectoryError):
        return False
    return stat.S_ISREG(info.st_mode)


def working_files(indexed):
    untracked = git("ls-files", "--others", "--exclude-standard", "-z")
    paths = set(indexed)
    paths.update(
        name.decode("utf-8", errors="surrogateescape")
        for name in untracked.split(b"\0") if name
    )
    return {path for path in paths if is_working_file(path)}


def import_source(data):
    """Read the generated source_file string and allow keep/skip sidecars."""
    section = ""
    importer = ""
    sources = []
    for line in data.decode("utf-8-sig").split("\n"):
        line = line.strip()
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
        key, _, value = line.partition("=")
        if section == "remap" and key.strip() == "importer":
            importer = value.strip()
        if section == "deps" and key.strip() == "source_file":
            sources.append(value.strip())
    if not sources and importer in {'"keep"', '"skip"'}:
        return None
    if len(sources) == 1:
        source = json.loads(sources[0])
        if isinstance(source, str) and source.startswith("res://"):
            return source
    raise ValueError("could not verify [deps] source_file")


def findings(paths, read):
    for name in sorted(paths):
        path = PurePosixPath(name)
        suffix = path.suffix
        if suffix in {".uid", ".import"}:
            source = name[:-len(suffix)]
            if source not in paths:
                yield "error", f"orphaned {name!r}; source {source!r} is absent from this snapshot"
                continue
            data = read(name)
            if suffix == ".uid":
                if not re.fullmatch(rb"uid://[a-z0-9]+", data.strip()):
                    yield "info", f"{name!r} does not look like a generated UID sidecar"
                continue
            try:
                declared = import_source(data)
            except ValueError:
                yield "info", f"could not verify [deps] source_file in {name!r}"
                continue
            expected = f"res://{source}"
            if declared is not None and declared != expected:
                yield "error", f"{name!r} declares {declared!r}; expected {expected!r}"
            continue

        if any(part.startswith(".") for part in path.parts) or any(
            (parent / ".gdignore").as_posix() in paths for parent in path.parents
        ):
            continue
        if suffix.lower() in UID_SOURCES and name + ".uid" not in paths:
            yield "info", (
                f"missing expected UID sidecar {name + '.uid'!r}. Review the finding "
                "and generate the sidecar through an authorized Godot import before "
                "final production validation."
            )
        if suffix.lower() in IMPORT_CANDIDATES and name + ".import" not in paths:
            yield "info", f"missing {name + '.import'!r} if this asset is imported"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--working-tree", action="store_true",
        help="check current tracked and unignored untracked files",
    )
    args = parser.parse_args()

    errors = notices = 0
    try:
        indexed = indexed_files()
        if args.working_tree:
            paths = working_files(indexed)
            reports = findings(paths, lambda path: (ROOT / path).read_bytes())
        else:
            paths = indexed.keys()
            reports = findings(paths, lambda path: git("cat-file", "blob", indexed[path]))
        for level, message in reports:
            print(f"{level}: {message}")
            errors += level == "error"
            notices += level == "info"
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"metadata check could not complete: {exc}", file=sys.stderr)
        return 2

    snapshot = "working tree" if args.working_tree else "Git index"
    print(f"{snapshot}: {errors} error(s), {notices} informational finding(s)")
    return int(errors > 0)


if __name__ == "__main__":
    sys.stdout.reconfigure(errors="backslashreplace")
    sys.stderr.reconfigure(errors="backslashreplace")
    sys.exit(main())
