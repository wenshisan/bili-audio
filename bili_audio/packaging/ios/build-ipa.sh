#!/usr/bin/env bash
# 有 Apple 分发证书和描述文件时打出可 OTA 安装的 IPA。没配 secrets 时直接成功退出。
set -euo pipefail

cd "$(dirname "$0")/../.."

if [ -z "${IOS_CERTIFICATE_P12_BASE64:-}" ] || [ -z "${IOS_PROVISIONING_PROFILE_BASE64:-}" ]; then
  echo "iOS signing secrets are not set; skipping IPA."
  exit 0
fi

KEYCHAIN="${RUNNER_TEMP:-/tmp}/app-signing.keychain-db"
CERT="${RUNNER_TEMP:-/tmp}/cert.p12"
PROFILE="${RUNNER_TEMP:-/tmp}/profile.mobileprovision"
DECODED="${RUNNER_TEMP:-/tmp}/profile.plist"
EXPORT="${RUNNER_TEMP:-/tmp}/ExportOptions.plist"

cleanup() {
  security delete-keychain "$KEYCHAIN" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "$IOS_CERTIFICATE_P12_BASE64" | base64 -D > "$CERT"
echo "$IOS_PROVISIONING_PROFILE_BASE64" | base64 -D > "$PROFILE"

security create-keychain -p "" "$KEYCHAIN"
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "" "$KEYCHAIN"
security import "$CERT" -P "${IOS_CERTIFICATE_PASSWORD:-}" -A -t cert -f pkcs12 -k "$KEYCHAIN"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "" "$KEYCHAIN"
security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | sed -e 's/"//g')

security cms -D -i "$PROFILE" > "$DECODED"
UUID=$(/usr/libexec/PlistBuddy -c 'Print UUID' "$DECODED")
PROFILE_NAME=$(/usr/libexec/PlistBuddy -c 'Print Name' "$DECODED")
TEAM=$(/usr/libexec/PlistBuddy -c 'Print TeamIdentifier:0' "$DECODED")
IDENTITY=$(security find-identity -v -p codesigning "$KEYCHAIN" | sed -n 's/.*"\(.*\)".*/\1/p' | head -1)
mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp "$PROFILE" "$HOME/Library/MobileDevice/Provisioning Profiles/$UUID.mobileprovision"

export TEAM PROFILE_NAME IDENTITY
python3 - << 'PY'
import os
from pathlib import Path
team = os.environ["TEAM"]
name = os.environ["PROFILE_NAME"].replace('"', '\\"')
identity = os.environ["IDENTITY"].replace('"', '\\"')
path = Path("ios/Runner.xcodeproj/project.pbxproj")
text = path.read_text()
old = """\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.bilimusic.biliAudio;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_OBJC_BRIDGING_HEADER = "Runner/Runner-Bridging-Header.h";"""
new = f"""\t\t\t\t"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "{identity}";
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tDEVELOPMENT_TEAM = {team};
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.bilimusic.biliAudio;
\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "{name}";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_OBJC_BRIDGING_HEADER = "Runner/Runner-Bridging-Header.h";"""
count = text.count(old)
if count == 0:
    raise SystemExit("Runner signing block not found")
path.write_text(text.replace(old, new))
print(f"patched {count} Runner configs")
PY

METHOD="${IOS_EXPORT_METHOD:-ad-hoc}"
cat > "$EXPORT" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>${METHOD}</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>teamID</key>
  <string>${TEAM}</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>com.bilimusic.biliAudio</key>
    <string>${PROFILE_NAME}</string>
  </dict>
  <key>compileBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <false/>
</dict>
</plist>
EOF

flutter pub get
flutter build ipa --release --export-options-plist="$EXPORT"
mkdir -p dist
ipa=$(find build/ios/ipa -name '*.ipa' | head -1 || true)
if [ -z "${ipa:-}" ]; then
  echo "flutter build ipa did not produce an IPA"
  exit 1
fi
cp "$ipa" dist/bili_audio-ios.ipa
echo "wrote dist/bili_audio-ios.ipa"
