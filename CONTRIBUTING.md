# Contributing

Issues and pull requests are welcome. Include your macOS version, CPU architecture, and steps to reproduce. For power-state problems, include the output of `pmset -g` after removing anything you consider private.

Build with Swift 6 or newer on macOS 14 or later:

```sh
./Scripts/test.sh
./Scripts/build-app.sh
build/SleepSwitch.app/Contents/MacOS/SleepSwitch --status
```

Keep the app small and dependency-free. Tests should cover meaningful behavior without changing the host's power settings, sudoers rules, or login items. Make UI checks with only one copy of SleepSwitch running so its global hotkey can register. Only test sleep toggling when you intend to change the system setting, and restore its previous value afterward.

See [release instructions](Docs/RELEASING.md) for universal builds and packaging. Contributions are distributed under the project's MIT license.
