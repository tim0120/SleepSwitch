#!/usr/bin/env zsh
set -euo pipefail

LABEL="local.tim.SleepSwitch"
PLIST_PATH="/Users/tim/Library/LaunchAgents/${LABEL}.plist"
USER_DOMAIN="gui/$(/usr/bin/id -u)"

if /bin/launchctl print "${USER_DOMAIN}/${LABEL}" >/dev/null 2>&1; then
  /bin/launchctl bootout "$USER_DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
fi

/bin/rm -f "$PLIST_PATH"
printf 'Removed %s\n' "$PLIST_PATH"
