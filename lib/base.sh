STDERR() { cat - 1>&2; }

exec_at_dir() { bash -c 'cd "$1" && shift && "$@"' exec-at-dir "$@"; }

get_array_index() {
  local -r key="$1"; shift
  local -i index=0
  while test $# -gt 0; do
    test "$1" = "$key" && echo $index && break
    index+=1; shift
  done
}

hascmd() { for i in "$@"; do typeof "$i" >/dev/null 2>&1 || return; done ;}

# Examples:
# shell_name 'ash*' && echo "Ash or one of its variants"
# shell_name (prints the shell name when no args)
shell_name() {
  local result="$(basename "$(readlink -f /proc/$$/exe)")"
  test "$1" || { test "$result" && echo $result; return ;}
  case "$result" in $1) return;; esac; return 1
}

# Prints only a word to describe the type of the first argument
# (alias, builtin, function, file)
typeof() {

# type --help -> ok in BusyBox Ash
  type --help >/dev/null 2>&1 || {
    # type -t: err in dash and zsh
    # Bash
    type -t >/dev/null 2>&1 && { type -t "$1"; return ;}
  }

  # Ash, Dash, ZSH
  local result="$(type "$1")"
  echo $result | grep -oq 'not found' && return 1
  echo $result | grep -oq alias && result=alias
  result="${result% from zsh}"; result="${result##* }"; test ${result##/*} || result=file
  echo $result

}

# Debian GNU/Linux 8 (jessie) [8.5]
# Ubuntu precise (12.04.5 LTS) [wheezy/sid]
# Ubuntu 14.04.4 LTS [jessie/sid]
# Mac OS X [10.6.4]
os_version() { (
  test -f /etc/os-release && . /etc/os-release
  local VERSION="$VERSION_ID"
  test -f /etc/debian_version && VERSION="$(cat /etc/debian_version)"
  test -z "$VERSION" && which sw_vers && \
    VERSION="$(sw_vers -productVersion)" && PRETTY_NAME="Mac OS X"
  echo "$PRETTY_NAME [$VERSION]"
) }
