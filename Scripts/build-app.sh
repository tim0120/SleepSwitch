#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/SleepSwitch.app"

ARCHITECTURE="${1:-native}"
SIGN_IDENTITY="${SLEEPSWITCH_SIGN_IDENTITY:--}"
case "$ARCHITECTURE" in
  native|universal) ;;
  *) printf 'Usage: %s [native|universal]\n' "$0" >&2; exit 2 ;;
esac

mkdir -p "$ROOT_DIR/build"
if [[ "$ARCHITECTURE" == universal ]]; then
  for arch in arm64 x86_64; do
    scratch="$ROOT_DIR/.build/$arch"
    xcrun swift build --package-path "$ROOT_DIR" --scratch-path "$scratch" \
      -c release --product SleepSwitch --triple "$arch-apple-macosx14.0"
    bin_dir="$(xcrun swift build --package-path "$ROOT_DIR" --scratch-path "$scratch" \
      -c release --triple "$arch-apple-macosx14.0" --show-bin-path)"
    cp "$bin_dir/SleepSwitch" "$ROOT_DIR/build/SleepSwitch-$arch"
  done
  xcrun lipo -create "$ROOT_DIR/build/SleepSwitch-arm64" \
    "$ROOT_DIR/build/SleepSwitch-x86_64" -output "$ROOT_DIR/build/SleepSwitch"
else
  xcrun swift build --package-path "$ROOT_DIR" -c release --product SleepSwitch
  bin_dir="$(xcrun swift build --package-path "$ROOT_DIR" -c release --show-bin-path)"
  cp "$bin_dir/SleepSwitch" "$ROOT_DIR/build/SleepSwitch"
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$ROOT_DIR/build/SleepSwitch" "$APP_DIR/Contents/MacOS/SleepSwitch"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
chmod +x "$APP_DIR/Contents/MacOS/SleepSwitch"
plutil -lint "$APP_DIR/Contents/Info.plist"

if [[ "$SIGN_IDENTITY" == - ]]; then
  codesign --force --sign - "$APP_DIR"
else
  codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp "$APP_DIR"
fi
codesign --verify --strict --verbose=2 "$APP_DIR"

printf '%s\n' "$APP_DIR"
