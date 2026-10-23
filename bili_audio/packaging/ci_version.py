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


def _order(raw: str) -> tuple[int, int, int, int] | None:
    parsed = parse_version(raw)
    if parsed is None:
        return None
    major, minor, patch, build = parsed
    return (major, minor, patch, 0 if build is None else build)


def previous_tag(lines: list[str], current: str) -> str | None:
    """在已发布标签里找比 [current] 旧的最高版本。"""
    current_key = _order(current)
    if current_key is None:
        return None
    best: str | None = None
    best_key: tuple[int, int, int, int] | None = None
    for line in lines:
        key = _order(line)
        if key is None or key >= current_key:
            continue
        if best_key is None or key > best_key:
            best = line.strip()
            best_key = key
    return best


def changelog_notes(subjects: list[str]) -> str:
    """把提交说明收成升级界面要显示的那一节。"""
    items: list[str] = []
    for subject in subjects:
        text = subject.strip()
        if text and text not in items:
            items.append(text)
    lines = ["## 更新日志", ""]
    if items:
        lines.extend(f"- {item}" for item in items)
    else:
        lines.append("本次没有单独列出的改动。")
    return "\n".join(lines) + "\n"


def release_notes(
    subjects: list[str],
    sha: str,
    version: str,
    run_url: str,
) -> str:
    """发布说明。应用内升级只读「更新日志」，后面的安装包说明留在 Release 页。"""
    installers = f"""## 安装包

由 `{sha}` 构建。版本 `{version}`。

| 平台 | 文件 |
| --- | --- |
| Android | `bili_audio-android.apk` |
| Windows | `bili_audio-windows-x64-setup.exe` |
| Linux | `bili_audio-linux-amd64.deb` |
| macOS (Apple 芯片) | `bili_audio-macos-arm64.dmg` |
| iOS | `bili_audio-ios.ipa`（描述文件安装，需签名 secrets） |

构建号每次加一，已安装的客户端才能覆盖安装并提示升级。`continuous` 仍是预发布，只给介绍页做固定下载地址。

构建日志：{run_url}
"""
    return changelog_notes(subjects) + "\n" + installers


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
    parser.add_argument("--pubspec", type=Path)
    parser.add_argument("--stamp", action="store_true")
    parser.add_argument("--version")
    parser.add_argument("--releases", type=Path)
    parser.add_argument("--ref-type", default="branch")
    parser.add_argument("--ref-name", default="")
    parser.add_argument("--previous-tag", action="store_true")
    parser.add_argument("--current")
    parser.add_argument("--notes-file", type=Path)
    parser.add_argument("--subjects", type=Path)
    parser.add_argument("--sha", default="")
    parser.add_argument("--run-url", default="")
    args = parser.parse_args(argv)

    lines: list[str] = []
    if args.releases is not None:
        lines = args.releases.read_text(encoding="utf-8").splitlines()

    if args.previous_tag:
        if not args.current:
            raise SystemExit("--previous-tag requires --current")
        found = previous_tag(lines, args.current)
        if found is not None:
            print(found)
        return

    if args.notes_file is not None:
        subjects: list[str] = []
        if args.subjects is not None:
            subjects = args.subjects.read_text(encoding="utf-8").splitlines()
        args.notes_file.write_text(
            release_notes(subjects, args.sha, args.version or "", args.run_url),
            encoding="utf-8",
        )
        return

    if args.pubspec is None:
        raise SystemExit("--pubspec is required")

    if args.stamp:
        if not args.version:
            raise SystemExit("--stamp requires --version")
        stamp(args.pubspec, args.version)
        print(f"stamped {args.version}", file=sys.stderr)
        return

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
