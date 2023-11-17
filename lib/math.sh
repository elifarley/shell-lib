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

int2b64() { hex2bytes $(printf '%x\n' $1) | base64 | tr -d '\n' ;}

hex2b64_padded() { pipehex2bytes | base64 | tr -d '\n' | tr '+/' '-_' ;}
hex2b64() { local r=$(hex2b64_padded); echo ${r%%=*} ;}

# Order-Preserving Base58 (OPB58).
# Also supports negative numbers.
int2b58() {
  # Omit IOlo
  local n="$1" i BASE58=$(echo {0..9} {A..H} {J..N} {P..Z} {a..k} {m..n} {p..z} | tr -d ' ')
  ((n < 0 )) && printf -- '-' && n=$((-n))
  for i in $(echo "obase=58; $n" | bc); do
    printf ${BASE58:$(( 10#$i )):1}
  done; echo
}

# Base36
int2b36() {
  local n="$1"; shift
  local BASE36=$(echo {0..9} {A..Z} | tr -d ' ')
  for i in $(echo "obase=36; $n" | bc); do
    printf ${BASE36:$(( 10#$i )):1}
  done; echo
}
