#!/bin/sh
# Example:
# github-install.sh elifarley/cross-installer /usr/local xinstall

CMD_BASE="$(readlink -f "$0")" || CMD_BASE="$0"; CMD_BASE="$(dirname "$CMD_BASE")"

test "$DEBUG" && set -x

dir_count_nodot() { test -d "$1" && echo $(\ls -Uq "$1" 2>/dev/null | wc -l ) ;}

githubInstall() {

local project="$1"; test $# -gt 0 && shift
local projname="$(basename "$project")"
test "$projname" || {
  echo "<projname> missing"; return 1
}
test "$projname" = "$project" && {
  echo "<project> must have a slash"; return 1
}

prefix="${1:-/usr/local}"; test $# -gt 0 && shift

executable="$1"; test $# -gt 0 && shift

test "$executable" -a -L "$prefix/bin/$executable" && {
  test -z "$FORCE" && {
    ls -Falk "$prefix/bin/$executable"
    echo "Previous installation exists. Aborting.
You can set env var 'FORCE=1' to force installation."
    exit 1
  }

  test "$projname" -a "$executable" && \
  rm -rf "$prefix/$projname" "$prefix/bin/$executable" || exit
}

mkdir "$prefix/$projname" && tmp="$(mktemp -d)" || exit

local_archive="$CMD_BASE/$projname".tgz
if test -s "$local_archive" ; then
  tar -xzf "$CMD_BASE/$projname".tgz -C "$tmp" || { rm -rf "$tmp"; exit 1 ;}

elif type curl >/dev/null 2>&1 ; then
  curl -fsSL "https://github.com/$project"/archive/master.tar.gz \
  | tar -xz -C "$tmp" || { rm -rfv "$tmp"; exit 1 ;}

else
  echo "Unable to download ''$projname'." && exit 1
fi

mv "$tmp"/*/* "$prefix/$projname" || { rm -rfv "$tmp"; exit 1 ;}
rm -rf "$tmp" || exit

test "$executable" || { # No executable defined ?
  # Only one executable found? TODO Create symlinks for bin/*
  test "$(dir_count_nodot "$prefix/$projname/bin")" -eq 1 && \
    executable="$(basename $(find "$prefix/$projname"/bin -mindepth 1 -name '.*' -prune -o -print -quit))"
}

test "$executable" \
  ln -sv ../"$projname/bin/$executable" "$prefix"/bin

}
