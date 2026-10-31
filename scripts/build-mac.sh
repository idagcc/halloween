#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# Prefer the complete Xcode toolchain without changing the machine's selection.
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
APP_PATH="$PROJECT_ROOT/dist/Pumpkin Pop.app"
WORK_PATH="$PROJECT_ROOT/.build/mac"
mkdir -p "$WORK_PATH" "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources/Game"

for architecture in arm64 x86_64; do
  xcrun swiftc -O -parse-as-library -sdk "$SDK_PATH" -target "${architecture}-apple-macos13.0" \
    -framework AppKit -framework WebKit mac/PumpkinPop.swift \
    -o "$WORK_PATH/PumpkinPop-$architecture"
done
xcrun lipo -create "$WORK_PATH/PumpkinPop-arm64" "$WORK_PATH/PumpkinPop-x86_64" \
  -output "$APP_PATH/Contents/MacOS/PumpkinPop"
cp mac/Info.plist "$APP_PATH/Contents/Info.plist"
cp index.html "$APP_PATH/Contents/Resources/Game/index.html"

xcrun swift -sdk "$SDK_PATH" mac/MakeIcon.swift "$WORK_PATH/icon.png"
ICONSET_PATH="$WORK_PATH/AppIcon.iconset"
mkdir -p "$ICONSET_PATH"
for pixels in 16 32 128 256 512; do
  sips -z "$pixels" "$pixels" "$WORK_PATH/icon.png" --out "$ICONSET_PATH/icon_${pixels}x${pixels}.png" >/dev/null
  retina_pixels=$((pixels * 2))
  sips -z "$retina_pixels" "$retina_pixels" "$WORK_PATH/icon.png" --out "$ICONSET_PATH/icon_${pixels}x${pixels}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET_PATH" -o "$APP_PATH/Contents/Resources/AppIcon.icns"
plutil -lint "$APP_PATH/Contents/Info.plist"
codesign --force --sign - --options runtime "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$PROJECT_ROOT/dist/Pumpkin-Pop-Mac.zip"
printf 'Built universal Mac app: %s\n' "$APP_PATH"
