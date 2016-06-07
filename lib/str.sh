strsplit() { (( $# == 3 )) || { echo "Usage: $FUNCNAME <str> <separator> <outvarname>"; return 1 ;}
  IFS="$2" read -a "$3" <<< "$1"
}

# Disable file globbing; coalesce inner whitespace;
# trim leading and trailing whitespace
trim() { (set -f; echo $@) ;}
strcontains() { test -z "${1##*$2*}" ; }; export -f strcontains
strendswith() { test ! "${1%%*$2}"; }
strstartswith() { test ! "${1##$2*}"; }
# See http://mywiki.wooledge.org/BashPitfalls#if_.5B.5B_.24foo_.3D.2BAH4_.27some_RE.27_.5D.5D
contains_asterisk() { local ASTERISK='\*'; [[ $1 =~ $ASTERISK ]] ;}

escape_quotes() {
  result=''
  for i in "$@"; do
    result="$result \"${i//\"/\\\"}\""
  done;
  echo $result
}
