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

shell_name() {
  # Try readlink /proc/$$/exe
  type --help >/dev/null 2>&1 && echo 'ash-busybox' && return
  type -t >/dev/null 2>&1 && echo 'bash' && return
  test "${SHELL##*/}" && echo ${SHELL##*/} && return
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

os_version() { (
  test -f /etc/os-release && . /etc/os-release
  local VERSION="$VERSION_ID"
  test -f /etc/debian_version && VERSION="$(cat /etc/debian_version)"
  echo "$PRETTY_NAME [$VERSION]"
) }
