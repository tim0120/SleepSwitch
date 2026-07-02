#!/usr/bin/env zsh
set -euo pipefail

LABEL="local.tim.SleepSwitch"
APP_PATH="/Users/tim/Applications/SleepSwitch.app"
EXECUTABLE_PATH="${APP_PATH}/Contents/MacOS/SleepSwitch"
PLIST_PATH="/Users/tim/Library/LaunchAgents/${LABEL}.plist"
USER_DOMAIN="gui/$(/usr/bin/id -u)"

if [[ ! -d "$APP_PATH" ]]; then
  printf 'SleepSwitch app not found at %s\n' "$APP_PATH" >&2
  exit 1
fi

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  printf 'SleepSwitch executable not found at %s\n' "$EXECUTABLE_PATH" >&2
  exit 1
fi

/bin/mkdir -p "$(/usr/bin/dirname "$PLIST_PATH")"

/bin/cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${LABEL}</string>
	<key>ProgramArguments</key>
	<array>
		<string>${EXECUTABLE_PATH}</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
EOF

/bin/chmod 0644 "$PLIST_PATH"
/usr/bin/plutil -lint "$PLIST_PATH" >/dev/null

if /bin/launchctl print "${USER_DOMAIN}/${LABEL}" >/dev/null 2>&1; then
  /bin/launchctl bootout "$USER_DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
fi

/bin/launchctl bootstrap "$USER_DOMAIN" "$PLIST_PATH"
/bin/launchctl kickstart -k "${USER_DOMAIN}/${LABEL}" >/dev/null 2>&1 || true

printf 'Installed %s\n' "$PLIST_PATH"
