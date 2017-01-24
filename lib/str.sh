# Disable file globbing; coalesce inner whitespace;
# trim leading and trailing whitespace
trim() { (set -f; echo $@) ;} # TODO Does not work in ZSH
strcontains() { test -z "${1##*$2*}" ; }; shell_name bash && export -f strcontains
strendswith() { test ! "${1%%*$2}"; }
strstartswith() { test ! "${1##$2*}"; }
charcount() {
  local char="$1"; shift;
  result="$(echo "$*" | tr -cd "$char")"; result=${#result};
  test $result -gt 0 && echo $result
}
charexists() {
  local char="$1"; shift
  case "$*" in *"$char"*) return;; esac; return 1
}

# Get the value of a key in a properties file
# Usage: getprop <file path> <key>
getprop() { trim "$(grep -m1 "^\s*$(echo $2 | tr -s . '\.')\s*=" "$1" | cut -d= -f2-)" ;}

escape_quotes() {
  result=''
  for i in "$@"; do
    result="$result \"${i//\"/\\\"}\""
  done;
  echo $result
}
