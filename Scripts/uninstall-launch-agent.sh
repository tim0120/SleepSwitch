#!/bin/bash
set -euo pipefail

USER_DOMAIN="gui/$(/usr/bin/id -u)"
for label in io.github.tim0120.SleepSwitch local.tim.SleepSwitch; do
  if /bin/launchctl print "${USER_DOMAIN}/${label}" >/dev/null 2>&1; then
    /bin/launchctl bootout "${USER_DOMAIN}/${label}"
  fi
  plist_path="$HOME/Library/LaunchAgents/${label}.plist"
  rm -f "$plist_path"
  printf 'Removed %s\n' "$plist_path"
done
