#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/SleepSwitch.app"

swift build --package-path "$ROOT_DIR" -c release
BIN_DIR="$(swift build --package-path "$ROOT_DIR" -c release --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN_DIR/SleepSwitch" "$APP_DIR/Contents/MacOS/SleepSwitch"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
chmod +x "$APP_DIR/Contents/MacOS/SleepSwitch"

codesign --force --deep --sign - "$APP_DIR" >/dev/null

printf '%s\n' "$APP_DIR"
