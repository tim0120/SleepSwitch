# Changelog

## 0.2.0 — 2026-10-06

First open-source release.

- MIT license, installation guide, and contribution instructions.
- Universal macOS app, ZIP and drag-to-Applications DMG with checksums.
- Portable optional login scripts and an app icon.
- Build verification in GitHub Actions and optional Developer ID signing and notarization.
- Strict parsing of sleep status; unavailable or invalid settings cannot trigger a toggle.
- Correctly recognizes fresh macOS defaults before a sleep override has been saved.
- About panel explaining persistent system sleep behavior and a read-only `--status` diagnostic.

## 0.1.0

- Original personal menu bar utility, global shortcut, CLI, and optional passwordless toggle.
