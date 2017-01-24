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
  local result; shell_name bash && result="${_dict[$(ht $key)]}" || {
    echo "Shell not supported: $(shell_name)"
    return 1
  }
  [[ -z $result ]] && echo "[ht_get] ERROR: Key not found: '$key'" | STDERR && return 1
  echo "$result"
}
