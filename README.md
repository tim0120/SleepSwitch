# SleepSwitch

<img src="Resources/AppIcon.png" alt="SleepSwitch moon icon" width="96" height="96">

A tiny, free macOS menu bar app that switches system sleep on and off, including lid-triggered sleep on supported Macs. Useful for long-running jobs when you close your MacBook.

[Download the Mac app](https://github.com/tim0120/SleepSwitch/releases/latest) · [Report an issue](https://github.com/tim0120/SleepSwitch/issues) · [MIT license](LICENSE)

**macOS 14 Sonoma or later · Apple Silicon and Intel · No dependencies**

## Install

1. Download `SleepSwitch-<version>-universal.dmg` from [Releases](https://github.com/tim0120/SleepSwitch/releases/latest). A ZIP is also available.
2. Open the DMG and drag **SleepSwitch.app** onto **Applications**. For a ZIP, extract it and move the app into Applications.
3. Open SleepSwitch. Look for its moon icon in the menu bar.

The first public release is **ad hoc signed and not notarized by Apple**. macOS may block its first launch. If you trust the release, attempt to open it, then go to **System Settings → Privacy & Security → Open Anyway**. See [Apple's instructions](https://support.apple.com/en-us/102445). Developer ID signing and notarization are supported by the release scripts for future releases.

You can also [build from source](#build-from-source). `SHA256SUMS.txt` accompanies each download so you can verify the downloaded files with `shasum -a 256 -c SHA256SUMS.txt` when both packages are in the same folder.

## Use

- Click the menu bar icon, then **Block Sleep** or **Restore Normal Sleep**.
- Press **Control–Option–Command–S** to toggle from anywhere.
- The menu reads the actual system setting whenever you open it, including changes made outside SleepSwitch.
- A moon indicates normal sleep, a crossed moon indicates blocked sleep, and a dot indicates an unavailable status. An unavailable status disables toggling.

Changing the setting requires administrator authentication. The app first tries a noninteractive `sudo` command; without the optional passwordless rule, it shows the macOS administrator prompt. SleepSwitch needs no Accessibility permission and contains no analytics, updater, or network requests.

**Sleep blocking persists after quitting, logging out, or restarting.** Restore normal sleep before putting a MacBook in a bag. Blocking sleep can drain the battery and cause heat buildup. Hardware and macOS behavior can vary; this is a system sleep switch and does not separately keep the display lit.

## What it changes

SleepSwitch invokes only these power-setting commands:

```sh
/usr/bin/pmset -a disablesleep 1  # Block system sleep
/usr/bin/pmset -a disablesleep 0  # Restore normal sleep
```

`-a` applies the setting on battery and AC power. It reads state using `pmset -g`. macOS omits `SleepDisabled` when no override has been saved; readable live settings without that override indicate the default, normal sleep. This follows Apple's [pmset implementation](https://github.com/apple-oss-distributions/PowerManagement/blob/main/pmset/pmset.m) and [power-setting implementation](https://github.com/apple-oss-distributions/PowerManagement/blob/main/pmconfigd/PMSettings.m).

The app does not automatically undo the setting when it quits. To restore sleep without the app:

```sh
sudo /usr/bin/pmset -a disablesleep 0
```

## Optional setup

The download's `Extras` folder includes these scripts. In a source checkout, they are under `Scripts`.

### Toggle without repeated password prompts

```sh
./Scripts/install-passwordless-toggle.sh
```

This asks for administrator approval once and installs `/etc/sudoers.d/sleepswitch`, granting your current macOS user only these exact commands:

```sudoers
<your-user> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

Any process running as that user can then invoke those two commands without a password. This optional rule covers one user; installing it again replaces the existing rule. Remove it with `./Scripts/uninstall-passwordless-toggle.sh`.

### Open at login

In System Settings, use **General → Login Items & Extensions → Open at Login** to add the installed app. Alternatively:

```sh
./Scripts/install-launch-agent.sh /Applications/SleepSwitch.app
```

The script creates `~/Library/LaunchAgents/io.github.tim0120.SleepSwitch.plist` for your account and starts the app. With no argument it searches `/Applications`, then `~/Applications`. It also replaces the original personal version's login entry when upgrading. Remove the entry with `./Scripts/uninstall-launch-agent.sh`.

## Build from source

Install Apple's Command Line Tools (`xcode-select --install`) with Swift 6 or newer, then:

```sh
git clone https://github.com/tim0120/SleepSwitch.git
cd SleepSwitch
./Scripts/test.sh
./Scripts/build-app.sh
open build/SleepSwitch.app
```

The status tests need no third-party packages or full Xcode installation. Build both CPU architectures with `./Scripts/build-app.sh universal`. Create the release DMG, ZIP, and checksums with `./Scripts/package-release.sh`. See [release instructions](Docs/RELEASING.md) for signing and notarization.

The built app supports a read-only diagnostic:

```sh
build/SleepSwitch.app/Contents/MacOS/SleepSwitch --status
```

## Command line

```sh
./Scripts/sleep-switch status
./Scripts/sleep-switch block
./Scripts/sleep-switch normal
./Scripts/sleep-switch toggle
```

The CLI uses `sudo` and respects the same optional passwordless rule.

## Uninstall

Restore normal sleep, remove any optional login entry and passwordless rule, quit SleepSwitch, and move the app to Trash. Deleting the app does not restore sleep or remove optional setup.

## Contribute

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and the [changelog](CHANGELOG.md). SleepSwitch is available under the [MIT license](LICENSE).
