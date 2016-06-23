urlencode() {
    local LANG=C
    for i in $(seq 1 ${#1}); do
        local c="$(expr substr "$1" $i 1)"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;; 
        esac
    done; echo
}

hex2decimal() { printf '%u' "0x$1"; echo ;}

# Each element must be a number in [0-255], like '192.168.0.255'
# Example: dotdecimal2hex 192.168.0.255 2
# $1 - Input number in dot-decimal notation
# $2 - Number of chars in output for each group (default: 2)
dotdecimal2hex() { printf "%0${2:-2}x" ${1//./ }; echo ;}

dotdecimal2decimal() { printf "%0${2:-3}u" ${1//./ }; echo ;}

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

pause() { echo 'Press [ENTER] to continue...'; read; }
ask() { echo -en "$1 "; shift; read "$@"; }

confirm() {
  local msg="$1"; shift
  local proceed
  ask "${msg:-Confirm?} [Y/n]" proceed
  test "$(echo $proceed | tr [:upper:] [:lower:])" != n || exit 1
}

areYouSure() {
  local msg="$1"; shift
  local proceed
  ask "${msg:-Are you sure you want to proceed?} [yes/N]" proceed
  test "$(echo $proceed | tr [:upper:] [:lower:])" = yes || exit 1
}

create_empty_zip() {
  echo "Creating empty zip: '$1'"
  rmdir_if_exists "$1" || return
  "$JAVA_HOME"/bin/jar Mcvf "$1" no-file 2> nul
  test -e "$1"
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
}; shell_name bash && export -f win_sed_inline
