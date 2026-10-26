#!/usr/bin/env bash
# 打出单架构 macOS 磁盘映像。通用包在 CI 上容易把 xcodebuild 撑死。
# 用法：build-dmg.sh arm64|x64
# 两个架构都在 Apple Silicon runner 上编：arm64 本机，x64 交叉编译。
# （macos-15-intel 上 Flutter pub get 会长时间卡住。）
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
    # 只编 arm64，避免通用包占满 CI 内存。
    export FLUTTER_MACOS_ARM64_ONLY=true
    flutter config --enable-macos-arm64-only
    EXPECTED=arm64
    FORBIDDEN=x86_64
    DMG_NAME=bili_audio-macos-arm64.dmg
    ;;
  x64)
    # 在 Apple Silicon 上交叉编 x86_64。xcconfig 注释必须用 //，# 是预处理器指令。
    printf '\n// CI: Intel-only release build\nARCHS = x86_64\nEXCLUDED_ARCHS = arm64\n' \
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

APP_BUNDLE="build/macos/Build/Products/Release/bili_audio.app"
VOL_NAME="音赴光年"
mkdir -p dist
RW_DMG="dist/${DMG_NAME%.dmg}.rw.dmg"
FINAL_DMG="dist/$DMG_NAME"
MOUNT=""
rm -f "$RW_DMG" "$FINAL_DMG"

cleanup_dmg() {
  if [[ -n "$MOUNT" ]]; then
    hdiutil detach "$MOUNT" -force >/dev/null 2>&1 || true
    rmdir "$MOUNT" 2>/dev/null || true
  fi
  rm -f "$RW_DMG"
}
trap cleanup_dmg EXIT

# 先做可写映像，再放进 .app 和“应用程序”替身。
# 直接 -srcfolder 可能把替身展开成整个 /Applications。
APP_KB="$(du -sk "$APP_BUNDLE" | awk '{print $1}')"
hdiutil create \
  -size "$((APP_KB + 65536))k" \
  -fs HFS+ \
  -volname "$VOL_NAME" \
  -ov \
  "$RW_DMG"

MOUNT="$(mktemp -d)"
hdiutil attach "$RW_DMG" -mountpoint "$MOUNT" -nobrowse
ditto "$APP_BUNDLE" "$MOUNT/bili_audio.app"
# Finder 会把这个替身显示成“应用程序”，拖进去就是复制到 /Applications。
# 布局文件把应用放在左边、应用程序放在右边。按名称排列时替身会跑到左边。
ln -s /Applications "$MOUNT/Applications"
cp "$(dirname "$0")/dmg-layout.dsstore" "$MOUNT/.DS_Store"

if [[ ! -L "$MOUNT/Applications" ]]; then
  echo "Applications alias missing from disk image" >&2
  exit 1
fi

sync
hdiutil detach "$MOUNT"
rmdir "$MOUNT" 2>/dev/null || true
MOUNT=""

hdiutil convert "$RW_DMG" -format UDZO -ov -o "$FINAL_DMG"
rm -f "$RW_DMG"
