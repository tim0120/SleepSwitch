# Releasing SleepSwitch

1. Update `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist` and add release notes in `CHANGELOG.md`.
2. Run `./Scripts/test.sh`, then `./Scripts/package-release.sh`. The script builds both architectures and creates a DMG, ZIP, and SHA-256 checksums in `dist/`.
3. Verify the app signature, both CPU architectures, archive contents, and a read-only status check:

   ```sh
   codesign --verify --strict --verbose=2 build/SleepSwitch.app
   lipo -archs build/SleepSwitch.app/Contents/MacOS/SleepSwitch
   build/SleepSwitch.app/Contents/MacOS/SleepSwitch --status
   hdiutil verify dist/SleepSwitch-<version>-universal.dmg
   ```

4. Commit and push, tag the tested commit as `v<version>`, and publish a GitHub Release with the DMG, ZIP, and `SHA256SUMS.txt`. Describe the actual signing and notarization status in its notes. The CI build verifies source changes and stores packages as workflow artifacts; publication is a separate maintainer action.

## Developer ID signing and notarization

The default build uses an ad hoc signature, which provides no verified developer identity and is **not notarized**. A download may require an explicit Gatekeeper exception. For easier installation, obtain a Developer ID Application certificate from the Apple Developer Program, install it in your local keychain, and store notarization credentials with `xcrun notarytool store-credentials`.

```sh
SLEEPSWITCH_SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
SLEEPSWITCH_NOTARY_PROFILE='sleepswitch-notary' \
  ./Scripts/package-release.sh
```

This enables the hardened runtime and secure signing timestamp, submits the app to Apple, staples its ticket before packaging, then submits and staples the DMG. Only describe a release as notarized after these operations succeed. Credentials and certificates belong in the keychain, never in the repository.

See [Apple's Developer ID guidance](https://developer.apple.com/developer-id/) and [notarization documentation](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Icon

The checked-in icon is generated from native AppKit drawing code:

```sh
xcrun swift Scripts/generate-icon.swift
iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns
```
