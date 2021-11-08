#!/bin/sh
test "$-" && echo "Not meant to be sourced" && return # if called via '.'
CMD_BASE="$(readlink -f "$0" 2>/dev/null || greadlink -f "$0")" || CMD_BASE="$0"; CMD_BASE="$(dirname "$CMD_BASE")"

# See (maybe) https://stackoverflow.com/a/23011530/299109
