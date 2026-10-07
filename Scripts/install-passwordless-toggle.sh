#!/usr/bin/env zsh
set -euo pipefail

USER_NAME="$(/usr/bin/id -un)"
if [[ ! "$USER_NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  printf 'This optional helper does not support this account name. Use the default admin prompt.\n' >&2
  exit 1
fi
RULE_PATH="/etc/sudoers.d/sleepswitch"
# A fixed directory keeps environment-provided paths out of the privileged shell.
TMP_RULE="$(/usr/bin/mktemp /private/tmp/sleepswitch-sudoers.XXXXXX)"

cleanup() {
  /bin/rm -f "$TMP_RULE"
}
trap cleanup EXIT

cat > "$TMP_RULE" <<EOF
# SleepSwitch: allow ${USER_NAME} to toggle only system sleep without a password.
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
/usr/bin/sudo -n -l /usr/bin/pmset -a disablesleep 0 >/dev/null
/usr/bin/sudo -n -l /usr/bin/pmset -a disablesleep 1 >/dev/null
printf 'SleepSwitch can now toggle without asking for your password.\n'
