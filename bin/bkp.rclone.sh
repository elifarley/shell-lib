#!/bin/sh
test "$-" && echo "Not meant to be sourced" && return # if called via '.'
CMD_BASE="$(readlink -f "$0" 2>/dev/null || greadlink -f "$0")" || CMD_BASE="$0"; CMD_BASE="$(dirname "$CMD_BASE")"
test "$DEBUG" && set -x

# Check also: borg backup
rclone \
copy --update --verbose --transfers 30 --checkers 8 \
--contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 \
--stats 60s --copy-links \
--filter-from "$CMD_BASE"/bkp.rclone.home.filter \
"$HOME" "gdrive:rclone.bkp/${HOME##*/}"

# --dry-run \
