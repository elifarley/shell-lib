#!/bin/sh
CMD_BASE="$(readlink -f "$0")" || CMD_BASE="$0"; CMD_BASE="$(dirname "$CMD_BASE")"
# See (maybe) https://stackoverflow.com/a/23011530/299109
