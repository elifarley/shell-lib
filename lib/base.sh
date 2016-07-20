STDERR() { cat - 1>&2; }

exec_at_dir() { bash -c 'cd "$1" && shift && "$@"' exec-at-dir "$@"; }

foreach() { local cmd="$1"; shift; for i; do $cmd "$i"; done ;}

# Example:
# myfunc() { for i; do echo $i; done ;}
# argsep , myfunc "1: a b,2: c" "3: d e,4:f"
argsep() {
  local _IFS="$1"; shift; local cmd="$1"; shift
  IFS="$_IFS" set -- $@
  $cmd "$@"
}

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
# CentOS Linux 7 (Core) [7]
# Fedora 23 (Twenty Three) [23]
# Mac OS X [10.6.4]
_os_version() { (
  test -f /etc/arch-release && echo 'Arch Linux []' && return
  test -f /etc/os-release && . /etc/os-release
  local VERSION="$VERSION_ID"
  test -f /etc/debian_version && VERSION="$(cat /etc/debian_version)"
  test -z "$VERSION" && {
    test -f /etc/redhat-release && cat /etc/redhat-release && return
    which 2>/dev/null >/dev/null sw_vers && \
    VERSION="$(sw_vers -productVersion)" && PRETTY_NAME="Mac OS X"
  }
  test "$PRETTY_NAME" -o "$VERSION" && echo "$PRETTY_NAME [$VERSION]"
) }

os_version() {
  local result; result="$(_os_version)" || return
  test "$1" || { echo $result; return ;}
  local asterisk="$(echo "$1" | tr -cd '*')"; test "$asterisk" && asterisk="$1" || asterisk="$1*"
  case "$(echo "$result" | tr '[:upper:]' '[:lower:]')" in $asterisk) return;; esac; return 1
}
