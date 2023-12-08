#!/bin/bash
# printf "'%s'\n" "$@" # DEBUG
TIMEFORMAT='Elapsed time: %E'
time /bin/bash -e -o pipefail "$@"
