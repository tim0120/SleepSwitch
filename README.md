# SleepSwitch

Tiny macOS menu bar utility for toggling lid-closed sleep behavior.

SleepSwitch wraps:

```sh
sudo pmset -a disablesleep 1
sudo pmset -a disablesleep 0
```

The menu bar state is read from `pmset -g`, so it reflects changes made outside the app too.

## Controls

- Menu bar icon: shows normal, blocked, or unknown state
- Toggle item: `Block Sleep` / `Restore Normal Sleep`
- Global hotkey: Control-Option-Command-S
- `Refresh Status`: re-read `pmset -g`

Without the passwordless rule, toggling prompts for an administrator password because `pmset` changes system power settings.
With the rule installed, SleepSwitch toggles silently.

## Build

```sh
./Scripts/build-app.sh
open ./build/SleepSwitch.app
```

## Passwordless Toggle

```sh
./Scripts/install-passwordless-toggle.sh
```

This installs `/etc/sudoers.d/sleepswitch` for the current macOS user:

```sudoers
<your-user> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

Remove it with:

```sh
./Scripts/uninstall-passwordless-toggle.sh
```

## Open At Login

```sh
./Scripts/install-launch-agent.sh
```

This installs `/Users/tim/Library/LaunchAgents/local.tim.SleepSwitch.plist`, which starts `/Users/tim/Applications/SleepSwitch.app` at login.

Remove it with:

```sh
./Scripts/uninstall-launch-agent.sh
```

## CLI

```sh
./Scripts/sleep-switch status
./Scripts/sleep-switch block
./Scripts/sleep-switch normal
./Scripts/sleep-switch toggle
```

## Notes

When sleep is blocked, a MacBook can keep running with the lid closed. That is useful for long-running jobs, but it can drain battery or build heat if it is left active in a bag.
