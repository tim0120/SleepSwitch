#!/usr/bin/env zsh
set -euo pipefail

RULE_PATH="/etc/sudoers.d/sleepswitch"
ROOT_COMMAND="/bin/rm -f \"$RULE_PATH\" && /usr/sbin/visudo -cf /etc/sudoers >/dev/null"
ESCAPED_COMMAND="${ROOT_COMMAND//\\/\\\\}"
ESCAPED_COMMAND="${ESCAPED_COMMAND//\"/\\\"}"

/usr/bin/osascript -e "do shell script \"$ESCAPED_COMMAND\" with administrator privileges"
printf 'Removed %s\n' "$RULE_PATH"
