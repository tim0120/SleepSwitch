#!/usr/bin/env zsh
set -euo pipefail

USER_NAME="$(/usr/bin/id -un)"
RULE_PATH="/etc/sudoers.d/sleepswitch"
TMP_RULE="$(/usr/bin/mktemp "${TMPDIR:-/tmp}/sleepswitch-sudoers.XXXXXX")"

cleanup() {
  /bin/rm -f "$TMP_RULE"
}
trap cleanup EXIT

cat > "$TMP_RULE" <<EOF
# SleepSwitch: allow ${USER_NAME} to toggle only lid-closed sleep without a password.
${USER_NAME} ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
EOF

/usr/sbin/visudo -cf "$TMP_RULE" >/dev/null

ROOT_COMMAND=$(cat <<EOF
/bin/mkdir -p /etc/sudoers.d
/bin/cp "$TMP_RULE" "$RULE_PATH"
/usr/sbin/chown root:wheel "$RULE_PATH"
/bin/chmod 0440 "$RULE_PATH"
/usr/sbin/visudo -cf "$RULE_PATH" >/dev/null
/usr/sbin/visudo -cf /etc/sudoers >/dev/null || { /bin/rm -f "$RULE_PATH"; exit 1; }
EOF
)

ESCAPED_COMMAND="${ROOT_COMMAND//\\/\\\\}"
ESCAPED_COMMAND="${ESCAPED_COMMAND//\"/\\\"}"

/usr/bin/osascript -e "do shell script \"$ESCAPED_COMMAND\" with administrator privileges"

printf 'Installed %s\n' "$RULE_PATH"
printf 'Testing passwordless pmset access...\n'
/usr/bin/sudo -n /usr/bin/pmset -a disablesleep "$(/usr/bin/pmset -g | /usr/bin/awk 'tolower($1) == "sleepdisabled" { print $2; exit }')"
printf 'SleepSwitch can now toggle without asking for your password.\n'
