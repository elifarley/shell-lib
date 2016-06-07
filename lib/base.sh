pss() { ps -o pid,user,c,start,args -C "$1" --cols 2000 "$@" ;}

STDERR() { cat - 1>&2; }

hex2bytes () {
  local b=0; while (( b < ${#1} )) ; do
  printf "\\x${1:$b:2}"; ((b += 2)); done
}
pipehex2bytes () { while read -r b file; do hex2bytes $b; done ;}

int2b64() { hex2bytes $(printf '%x\n' $1) | base64 -w0 ;}

hex2b64_padded() { pipehex2bytes | base64 -w0 | tr '+/' '-_' ;}
hex2b64() { local r=$(hex2b64_padded); echo ${r%%=*} ;}

# TimeStamp in Decimal
millistamp() { local n=$(date +%s%N); echo "${n%??????}" ;}
# TimeStamp in Hex
millistamp_hex() { printf '%x\n' $(millistamp) ;}
# TimeStamp in Base64 - smaller, case-sensitive
millistamp_b64() { millistamp_hex | hex2b64 ;}

# See https://gist.github.com/earthgecko/3089509
mkrandom() { base64 -w0 /dev/urandom | tr -d "/+${2:-0Oo}" | dd bs="${1:-8}" count=1 2>/dev/null | xargs ;}
mkrandomL() { mkrandom "$@" | tr '[[:upper:]]' '[[:lower:]]' ;}
mkrandomU() { mkrandom "$@" | tr '[[:lower:]]' '[[:upper:]]' ;}

exec_at_dir() { bash -c 'cd "$1" && shift && "$@"' exec-at-dir "$@"; }

wait_file() {
  local file="$1"; shift
  local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout

  until test $((wait_seconds--)) -eq 0 -o -f "$file" ; do sleep 1; done

  ((++wait_seconds))
}

wait_str() {
  local file="$1"; shift
  local search_term="$1"; shift
  local wait_time="${1:-5m}"; shift # 5 minutes as default timeout

  (timeout $wait_time tail -F -n0 "$file" &) | grep -q "$search_term" && return 0

  echo "Timeout of $wait_time reached. Unable to find '$search_term' in '$file'"
  return 1
}

wait_jboss() {
  local server_log="$1"; shift
  local wait_time="$1"; shift
  wait_str "$server_log" "JBoss .* Started in " "$wait_time"
}

# See http://stackoverflow.com/questions/1494178/how-to-define-hash-tables-in-bash
ht() { local ht=$(echo "$@" | cksum); echo "${ht//[!0-9]}"; }
ht_get() {
  local key="$1"; shift
  (($#)) || { echo "[ht_get] ERROR: Missing map items" | STDERR && return 1; }
  (( $# == 1 )) && ! [[ "$1" =~ '=' ]] && echo "$1" && return
  local _dict k v i; unset _dict
  for i in "$@"; do
    [[ "$i" =~ '=' ]] || { echo "[ht_get] ERROR: Missing equals sign: '$i'" | STDERR; return 1; }
    k=${i%%=*}; v=${i#*=}; _dict[$(ht $k)]="$v"
  done
  local result="${_dict[$(ht $key)]}"
  [[ -z $result ]] && echo "[ht_get] ERROR: Key not found: '$key'" | STDERR && return 1
  echo "$result"
}

pause() { echo 'Pressione [ENTER] para continuar...'; read; }
ask() { echo -en "$1 "; shift; read "$@"; }

confirm() {
  local msg="$1"; shift
  local proceed
  ask "${msg:-Confirma?} [S/n]" proceed
  test "$(echo $proceed | tr [:upper:] [:lower:])" != n || exit 1
}

areYouSure() {
  local msg="$1"; shift
  local proceed
  ask "${msg:-Tem certeza de que deseja prosseguir?} [tenho/N]" proceed
  test "$(echo $proceed | tr [:upper:] [:lower:])" = tenho || exit 1
}

create_empty_zip() {
  echo "Creating empty zip: '$1'"
  rmdir_if_exists "$1" || return $?
  "$JAVA_HOME"/bin/jar Mcvf "$1" no-file 2> nul
  test -e "$1"
}

get_array_index() {
  local -r key="$1"; shift
  local -i index=0
  while test $# -gt 0; do
    test "$1" = "$key" && echo $index && break
    index+=1; shift
  done
}

foreachline() {
  local -r file="$1"; shift
  local index="$(get_array_index '{}' "$@")"
  test "$index" || { echo "Missing {}" && return 1; }
  local opts=("$@")

  while read -r line; do
    $(strstartswith "$line" '#') && continue
    opts[$index]="$line"; "${opts[@]}" || return $?
  done < "$file"
}

# This function operates on the current directory only.
# It is supposed to be called from a find command like this:
# find path ... -execdir bash -c 'win_sed_inline "$@"' bash "$@" {} +
# See http://unix.stackexchange.com/questions/50692/executing-user-defined-function-in-a-find-exec-call
win_sed_inline() {
  sed -i'.SED-BKP' -rs "$@" && \
  rmdir_if_exists *.SED-BKP 1> nul && \
  rmdir_if_exists sed?????? 1> nul
  # See http://stackoverflow.com/questions/1823591/sed-creates-un-deleteable-files-in-windows
}
export -f win_sed_inline

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
