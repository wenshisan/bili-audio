#!/usr/bin/env python3
"""为一次安装包构建决定版本号，或把该版本写进 pubspec。

版本名来自触发本次构建的 `vX.Y.Z` 标签；没有这种标签时用 pubspec。
构建号比 pubspec 和已发布 Release 里出现过的构建号都大 1。
安装包和正式版标签因此一次比一次新，已安装的客户端才能升级。
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Android versionCode 的上限。超过后系统拒绝安装。
_MAX_BUILD = 2_100_000_000
_VERSION = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$")
_PUBSPEC_VERSION = re.compile(r"^(version:\s*)(\S+)[ \t]*\r?$", re.MULTILINE)


def parse_version(raw: str) -> tuple[int, int, int, int | None] | None:
    """解析 `v1.2.3` 或 `1.2.3+4`。格式不对时返回 None。"""
    match = _VERSION.match(raw.strip())
    if match is None:
        return None
    major, minor, patch, build = match.groups()
    return (
        int(major),
        int(minor),
        int(patch),
        None if build is None else int(build),
    )


def decide(
    pubspec_text: str,
    release_lines: list[str],
    ref_type: str,
    ref_name: str,
) -> dict[str, str]:
    """返回这次构建要写入安装包和 GitHub Release 的版本字段。"""
    pubspec_match = _PUBSPEC_VERSION.search(pubspec_text)
    if pubspec_match is None:
        raise SystemExit("pubspec.yaml has no version")
    parsed = parse_version(pubspec_match.group(2))
    if parsed is None:
        raise SystemExit(f"cannot parse pubspec version {pubspec_match.group(2)}")
    major, minor, patch, pub_build = parsed

    if ref_type == "tag":
        # vX.Y.Z+N 是上次构建打上的标签。再算一版会再打一个标签。
        if "+" in ref_name:
            raise SystemExit(f"refusing to rebuild auto tag {ref_name}")
        tagged = parse_version(ref_name)
        if tagged is None:
            raise SystemExit(f"tag {ref_name} is not a version")
        major, minor, patch = tagged[0], tagged[1], tagged[2]

    highest = pub_build or 0
    for line in release_lines:
        seen = parse_version(line)
        if seen is not None and seen[3] is not None:
            highest = max(highest, seen[3])
    build = highest + 1
    if build > _MAX_BUILD:
        raise SystemExit(f"build number {build} exceeds Android versionCode")

    version = f"{major}.{minor}.{patch}+{build}"
    if ref_type == "tag":
        release_tag = ref_name
    else:
        release_tag = f"v{version}"
    return {
        "build_name": f"{major}.{minor}.{patch}",
        "build_number": str(build),
        "version": version,
        "release_tag": release_tag,
        "release_name": f"v{version}",
    }


def stamp(path: Path, version: str) -> None:
    """把 pubspec 的 version 改成 [version]，保留原来的换行。"""
    if parse_version(version) is None or parse_version(version)[3] is None:
        raise SystemExit(f"refusing to stamp {version}")
    text = path.read_text(encoding="utf-8")
    new, count = _PUBSPEC_VERSION.subn(rf"\g<1>{version}", text, count=1)
    if count != 1:
        raise SystemExit(f"no version line in {path}")
    path.write_text(new, encoding="utf-8")


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pubspec", required=True, type=Path)
    parser.add_argument("--stamp", action="store_true")
    parser.add_argument("--version")
    parser.add_argument("--releases", type=Path)
    parser.add_argument("--ref-type", default="branch")
    parser.add_argument("--ref-name", default="")
    args = parser.parse_args(argv)

    if args.stamp:
        if not args.version:
            raise SystemExit("--stamp requires --version")
        stamp(args.pubspec, args.version)
        print(f"stamped {args.version}", file=sys.stderr)
        return

    lines: list[str] = []
    if args.releases is not None:
        lines = args.releases.read_text(encoding="utf-8").splitlines()
    result = decide(
        args.pubspec.read_text(encoding="utf-8"),
        lines,
        args.ref_type,
        args.ref_name,
    )
    for key, value in result.items():
        print(f"{key}={value}")


if __name__ == "__main__":
    main()
