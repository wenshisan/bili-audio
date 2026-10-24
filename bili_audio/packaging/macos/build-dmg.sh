#!/usr/bin/env bash
# 打出单架构 macOS 磁盘映像。通用包在 CI 上容易把 xcodebuild 撑死。
# 用法：build-dmg.sh arm64|x64
# arm64 在 Apple Silicon runner 上编；x64 应在 Intel runner（如 macos-15-intel）上编。
set -euo pipefail

ARCH="${1:?usage: build-dmg.sh arm64|x64}"
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
APP="$ROOT/bili_audio"
cd "$APP"

HOST_ARCH="$(uname -m)"
echo "host arch: $HOST_ARCH; target: $ARCH"

flutter pub get

# 插件的 Package.swift / podspec 仍写着 macOS 10.14。Xcode 26 的最低部署版本是 11。
python3 - << 'PY'
import os, pathlib, re
cache = pathlib.Path(os.environ.get("PUB_CACHE", pathlib.Path.home() / ".pub-cache"))
hosted = cache / "hosted"
if not hosted.is_dir():
    raise SystemExit(f"pub cache not found: {hosted}")
swift = re.compile(r'\.macOS\("(10\.\d+|11\.0)"\)')
pod = re.compile(r"""(\.osx\.deployment_target\s*=\s*['"])(?:10\.\d+|11\.0)(['"])""")
changed = 0
for path in hosted.rglob("*"):
    if path.name == "Package.swift":
        text = path.read_text(encoding="utf-8")
        new, count = swift.subn('.macOS("12.0")', text)
    elif path.suffix == ".podspec":
        text = path.read_text(encoding="utf-8")
        new, count = pod.subn(r"\g<1>12.0\2", text)
    else:
        continue
    if count:
        path.write_text(new, encoding="utf-8")
        changed += count
print(f"raised {changed} macOS deployment targets to 12.0")
PY

case "$ARCH" in
  arm64)
    # Apple 芯片：只编 arm64，避免通用包占满 CI 内存。
    export FLUTTER_MACOS_ARM64_ONLY=true
    flutter config --enable-macos-arm64-only
    EXPECTED=arm64
    FORBIDDEN=x86_64
    DMG_NAME=bili_audio-macos-arm64.dmg
    ;;
  x64)
    # Intel runner 上 Release 默认仍是通用包；排除 arm64，只留 x86_64。
    if [[ "$HOST_ARCH" != "x86_64" ]]; then
      echo "x64 builds must run on an Intel Mac (host is $HOST_ARCH)" >&2
      exit 1
    fi
    # xcconfig 里用 // 写注释；# 会被当成预处理器指令。
    printf '\n// CI: Intel-only release build\nEXCLUDED_ARCHS = arm64\n' \
      >> macos/Runner/Configs/Release.xcconfig
    EXPECTED=x86_64
    FORBIDDEN=arm64
    DMG_NAME=bili_audio-macos-x64.dmg
    ;;
  *)
    echo "unknown arch: $ARCH (want arm64 or x64)" >&2
    exit 1
    ;;
esac

flutter build macos --release

BINARY="build/macos/Build/Products/Release/bili_audio.app/Contents/MacOS/bili_audio"
BUILT="$(lipo -archs "$BINARY")"
echo "built arches: $BUILT"
if ! grep -qw "$EXPECTED" <<<"$BUILT"; then
  echo "expected $EXPECTED in binary, got: $BUILT" >&2
  exit 1
fi
if grep -qw "$FORBIDDEN" <<<"$BUILT"; then
  echo "did not expect $FORBIDDEN in binary, got: $BUILT" >&2
  exit 1
fi

mkdir -p dist
hdiutil create \
  -volname "bili-audio" \
  -srcfolder "build/macos/Build/Products/Release/bili_audio.app" \
  -ov -format UDZO \
  "dist/$DMG_NAME"
