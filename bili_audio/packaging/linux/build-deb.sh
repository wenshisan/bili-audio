#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
BUNDLE="$ROOT/bili_audio/build/linux/x64/release/bundle"
RAW="$(awk '/^version:/ {print $2; exit}' "$ROOT/bili_audio/pubspec.yaml")"
VERSION="${RAW%%+*}"
STAGE="$(mktemp -d)"
OUT="$ROOT/bili_audio/dist"
mkdir -p "$OUT" \
  "$STAGE/opt/bili_audio" \
  "$STAGE/usr/bin" \
  "$STAGE/usr/share/applications" \
  "$STAGE/usr/share/icons/hicolor/256x256/apps" \
  "$STAGE/DEBIAN"

cp -a "$BUNDLE/." "$STAGE/opt/bili_audio/"
cp "$ROOT/bili_audio/assets/app_icon.png" \
  "$STAGE/usr/share/icons/hicolor/256x256/apps/bili_audio.png"

cat > "$STAGE/usr/bin/bili_audio" << 'EOF'
#!/bin/sh
exec /opt/bili_audio/bili_audio "$@"
EOF
chmod 755 "$STAGE/usr/bin/bili_audio"

cat > "$STAGE/usr/share/applications/bili_audio.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=bili-audio
Comment=第三方哔哩哔哩音乐播放器
Exec=/opt/bili_audio/bili_audio
Icon=bili_audio
Categories=Audio;Player;
Terminal=false
EOF

cat > "$STAGE/DEBIAN/control" << EOF
Package: bili-audio
Version: ${VERSION}
Section: sound
Priority: optional
Architecture: amd64
Maintainer: bili-audio <noreply@users.noreply.github.com>
Depends: libgtk-3-0 | libgtk-3-0t64, libblkid1, liblzma5
Description: Third-party Bilibili audio player
 Personal learning project. Not affiliated with Bilibili.
EOF

dpkg-deb --build --root-owner-group "$STAGE" "$OUT/bili_audio-linux-amd64.deb"
rm -rf "$STAGE"
