# Disable file globbing; coalesce inner whitespace;
# trim leading and trailing whitespace
trim() { (set -f; echo $@) ;}
strcontains() { test -z "${1##*$2*}" ; }; shell_name bash && export -f strcontains
strendswith() { test ! "${1%%*$2}"; }
strstartswith() { test ! "${1##$2*}"; }
charcount() {
  local char="$1"; shift;
  result="$(echo "$*" | tr -cd "$char")"; result=${#result};
  test $result -gt 0 && echo $result
}
charexists() { charcount "$@" >/dev/null ;}

escape_quotes() {
  result=''
  for i in "$@"; do
    result="$result \"${i//\"/\\\"}\""
  done;
  echo $result
}
