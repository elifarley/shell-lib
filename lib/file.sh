
some_file() { local base="$1"; shift; find -H "$base" ! -path "$base" "$@" -print -quit; }

dir_full() { local base="$1"; shift; test "$(cd "$base" &>nul && find -H . -maxdepth 1 ! -path . "$@" -print -quit)"; }

dir_not_empty() { test "$(ls -A "$@" 2>/dev/null)" ;}

dir_empty() { find -H "$1" -maxdepth 0 -empty | read v ;}

dir_count() { test -d "$1" && echo $(( $(\ls -afq "$1" 2>/dev/null | wc -l )  -2 )) ;}

existing_path() {
  local path="$1"
  until [[ $path == '.' || -e $path ]]; do
    path=$(dirname $path)
  done
  echo $path
}

path_owner() {
  local path="$(existing_path "$1")"
  echo $(stat -c '%U' $path)
}

safe_rm() {
  local suffix=".saferm"
  for i in "$@"; do
    test '/' = "$i" && echo "Invalid path: '$i'" && return 1
    test -e "$i" || continue
    echo "Removing '$i'..." && mv "$i" "$i$suffix" && rm -rf "$i$suffix" || return $?
  done
  return 0
}

# returns next-to-last path element
# default separator is /
ntl() { local separator="${1:-/}"; awk -F"$separator" 'NF>1 {print $(NF-1)}'; }

parentname() { local path="$1"; shift; local separator="$1"; shift; echo $path | ntl "$separator"; }

rmdir_if_exists() {
  local p; for p in "$@"; do
    test -e "$p" || continue
    echo "Removing '$p'"
    rm -r "$p" || return $?
  done
}; shell_name bash && export -f rmdir_if_exists

rmexp_if_exists() {
  # TODO make it work with paths that include spaces
  while test $# -gt 0; do
    for i in $(eval echo "$1"); do
      shift
      rmdir_if_exists "$i" || return 1
    done
  done
}

# Syntax is similar to rsync
cpdir() {
  test $# -eq 2 || { echo "Usage: cpdir <SRC> <DEST>"; return 1; }
  local src="$1"; shift
  local dest="$1"; shift
  local include_all=''; strendswith "$src" / && include_all='*'
  test -e "$dest" || { mkdir "$dest" || return $?; }
  cp -dr "$src"$include_all "$dest"
}

# Syntax is similar to rsync
cpdirm() {
  test $# -ge 2 || { echo "Usage: cpdirm [OPTION...]"; return 1; }

  local cpargs='' dest=''
  for p in "$@"; do
    test ! "${p##-*}" || {
      dest="$p"
      strendswith "$p" / && p="$p"'*'
    }
    cpargs="$cpargs '$p'"
  done
  test -e "$dest" || { mkdir "$dest" || return $?; }
  eval cp -dr $cpargs
}
