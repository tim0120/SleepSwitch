#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT_DIR/build"
xcrun swiftc -swift-version 6 "$ROOT_DIR/Sources/SleepSwitchCore/SleepStatus.swift" \
  "$ROOT_DIR/Tests/main.swift" -o "$ROOT_DIR/build/SleepSwitchStatusTests"
"$ROOT_DIR/build/SleepSwitchStatusTests"
