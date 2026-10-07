#!/bin/bash
set -euo pipefail

LABEL="io.github.tim0120.SleepSwitch"
if [[ $# -gt 1 ]]; then
  printf 'Usage: %s [path/to/SleepSwitch.app]\n' "$0" >&2
  exit 2
fi
if [[ $# -eq 1 ]]; then
  APP_PATH="$1"
elif [[ -d /Applications/SleepSwitch.app ]]; then
  APP_PATH="/Applications/SleepSwitch.app"
else
  APP_PATH="$HOME/Applications/SleepSwitch.app"
fi
if [[ ! -x "$APP_PATH/Contents/MacOS/SleepSwitch" ]]; then
  printf 'SleepSwitch app not found at %s. Pass the installed app path as an argument.\n' "$APP_PATH" >&2
  exit 1
fi
APP_PATH="$(cd "$APP_PATH" && pwd)"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"
USER_DOMAIN="gui/$(/usr/bin/id -u)"
mkdir -p "$HOME/Library/LaunchAgents"
TMP_PLIST="$(mktemp "$HOME/Library/LaunchAgents/.sleepswitch.XXXXXX")"
trap 'rm -f "$TMP_PLIST"' EXIT

# plutil escapes paths correctly, including spaces and XML characters.
/usr/bin/plutil -create xml "$TMP_PLIST"
/usr/bin/plutil -insert Label -string "$LABEL" "$TMP_PLIST"
/usr/bin/plutil -insert ProgramArguments -json '[]' "$TMP_PLIST"
/usr/bin/plutil -insert ProgramArguments.0 -string "$APP_PATH/Contents/MacOS/SleepSwitch" "$TMP_PLIST"
/usr/bin/plutil -insert RunAtLoad -bool true "$TMP_PLIST"
/usr/bin/plutil -lint "$TMP_PLIST"
chmod 0644 "$TMP_PLIST"

# Replace the previous personal version's login entry when upgrading.
for old_label in local.tim.SleepSwitch "$LABEL"; do
  if /bin/launchctl print "${USER_DOMAIN}/${old_label}" >/dev/null 2>&1; then
    /bin/launchctl bootout "${USER_DOMAIN}/${old_label}"
  fi
done
rm -f "$HOME/Library/LaunchAgents/local.tim.SleepSwitch.plist"
mv "$TMP_PLIST" "$PLIST_PATH"
/bin/launchctl bootstrap "$USER_DOMAIN" "$PLIST_PATH"
printf 'Installed %s\n' "$PLIST_PATH"
