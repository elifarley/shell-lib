foreachline() {
  local -r file="$1"; shift
  local index="$(get_array_index '{}' "$@")"
  test "$index" || { echo "Missing {}" && return 1; }
  local opts=("$@")

  while read -r line; do
    $(strstartswith "$line" '#') && continue
    opts[$index]="$line"; "${opts[@]}" || return
  done < "$file"
}

# fexec <exported-function-name>[:<extraopts>] <srcdir> [funcopt1 funcopt2 ... --] [findopt1 findopt2 ...]
# extraopts: d=execdir; m=+; x=maxdepth n
# example: x1%dm
fexec() {
  local fname="$1"; shift
  local srcdir="$1"; shift

  local funcopts=() findopts=()
  while test $# -gt 0; do
    test "$1" = '--' && { shift; funcopts=("${findopts[@]}"); findopts=("$@"); break; }
    findopts+=("$1") && shift
  done

  local exectype='-exec' argtype=';' maxdepth=''
  strcontains "$fname" : && { local extraopts="${fname##*:}" c
    while test "$extraopts"; do c=${extraopts:0:1}
      case "$c" in
        d) exectype='-execdir';;
        m) argtype='+';;
        x) maxdepth="${extraopts%%\%*}"
           extraopts="${extraopts#$maxdepth}"
           maxdepth="${maxdepth:1}"
           maxdepth="${maxdepth:-1}"
           ;;
      esac
    extraopts="${extraopts:1}"; done
  }

  PATH="$LINUX_BIN" find "$srcdir" ${maxdepth:+-maxdepth "$maxdepth"} -type f "${findopts[@]}" $exectype bash -c "${fname%%:*}"' "$@"' fexec-"$fname" "${funcopts[@]}" {} "$argtype"
}; export -f fexec
