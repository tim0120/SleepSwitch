#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT_DIR/build"
xcrun swiftc -parse-as-library \
  "$ROOT_DIR/Sources/SleepSwitchIcon/SleepSwitchIcon.swift" \
  "$ROOT_DIR/Scripts/generate-icon.swift" -o "$ROOT_DIR/build/GenerateIcon"
"$ROOT_DIR/build/GenerateIcon"
iconutil -c icns "$ROOT_DIR/build/AppIcon.iconset" -o "$ROOT_DIR/Resources/AppIcon.icns"
