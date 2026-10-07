#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")"
DIST_DIR="$ROOT_DIR/dist"
PACKAGE_NAME="SleepSwitch-$VERSION-universal"
STAGE_DIR="$ROOT_DIR/build/$PACKAGE_NAME"

"$ROOT_DIR/Scripts/build-app.sh" universal
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/Extras" "$DIST_DIR"
ditto "$ROOT_DIR/build/SleepSwitch.app" "$STAGE_DIR/SleepSwitch.app"
cp "$ROOT_DIR/LICENSE" "$STAGE_DIR/LICENSE.txt"
cp "$ROOT_DIR/Docs/INSTALL.txt" "$STAGE_DIR/INSTALL.txt"
cp "$ROOT_DIR/Scripts/"{sleep-switch,install-passwordless-toggle.sh,uninstall-passwordless-toggle.sh,install-launch-agent.sh,uninstall-launch-agent.sh} "$STAGE_DIR/Extras/"
# Discard optional local metadata before adding notarization tickets.
xattr -cr "$STAGE_DIR"

if [[ -n "${SLEEPSWITCH_NOTARY_PROFILE:-}" ]]; then
  if [[ "${SLEEPSWITCH_SIGN_IDENTITY:--}" == - ]]; then
    printf 'Notarization requires SLEEPSWITCH_SIGN_IDENTITY (Developer ID Application).\n' >&2
    exit 1
  fi
  notary_zip="$ROOT_DIR/build/SleepSwitch-notarization.zip"
  rm -f "$notary_zip"
  ditto -c -k --keepParent "$STAGE_DIR/SleepSwitch.app" "$notary_zip"
  xcrun notarytool submit "$notary_zip" --keychain-profile "$SLEEPSWITCH_NOTARY_PROFILE" --wait
  xcrun stapler staple "$STAGE_DIR/SleepSwitch.app"
  xcrun stapler validate "$STAGE_DIR/SleepSwitch.app"
fi

codesign --verify --strict --verbose=2 "$STAGE_DIR/SleepSwitch.app"
rm -f "$DIST_DIR/$PACKAGE_NAME.zip" "$DIST_DIR/$PACKAGE_NAME.dmg"
ditto -c -k --norsrc --noextattr --keepParent "$STAGE_DIR" "$DIST_DIR/$PACKAGE_NAME.zip"
# Verify the actual archived app, including its stapled ticket when notarized.
VERIFY_DIR="$ROOT_DIR/build/verify-release"
rm -rf "$VERIFY_DIR"
ditto -x -k "$DIST_DIR/$PACKAGE_NAME.zip" "$VERIFY_DIR"
codesign --verify --strict --verbose=2 "$VERIFY_DIR/$PACKAGE_NAME/SleepSwitch.app"
if [[ -n "${SLEEPSWITCH_NOTARY_PROFILE:-}" ]]; then
  xcrun stapler validate "$VERIFY_DIR/$PACKAGE_NAME/SleepSwitch.app"
fi
ln -s /Applications "$STAGE_DIR/Applications"
hdiutil create -volname "SleepSwitch $VERSION" -srcfolder "$STAGE_DIR" \
  -format UDZO -ov "$DIST_DIR/$PACKAGE_NAME.dmg"

if [[ -n "${SLEEPSWITCH_NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$DIST_DIR/$PACKAGE_NAME.dmg" \
    --keychain-profile "$SLEEPSWITCH_NOTARY_PROFILE" --wait
  xcrun stapler staple "$DIST_DIR/$PACKAGE_NAME.dmg"
  xcrun stapler validate "$DIST_DIR/$PACKAGE_NAME.dmg"
fi
(
  cd "$DIST_DIR"
  shasum -a 256 "$PACKAGE_NAME.zip" "$PACKAGE_NAME.dmg" > SHA256SUMS.txt
)
printf 'Release files: %s\n' "$DIST_DIR"
