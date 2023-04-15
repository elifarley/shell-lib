#!/bin/sh
CMD_BASE="$(readlink -f "$0" 2>/dev/null || greadlink -f "$0")" || CMD_BASE="$0"; CMD_BASE="$(dirname "$CMD_BASE")"

TRACKER_DIR="$(readlink -f "$CMD_BASE/../.cache/tracker" 2>/dev/null || greadlink -f "$CMD_BASE/../.cache/tracker")"
test -d "$TRACKER_DIR" || exit 0

killall /usr/lib/tracker-{miner-apps,extract,miner-fs,store}
du -hs "$TRACKER_DIR"
rm -rf "$TRACKER_DIR"
exit 0
