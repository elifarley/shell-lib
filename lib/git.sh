# shellcheck shell=dash

sid() {
  # $(date -d 2023-01-01 +%s) = 1672527600
  # 1672527600/60 = 27875460
  local ts="$1" author="$2" msg="$3"
  local rawSID pr="$(echo "$msg" | sed -En 's/.*\(#([0-9]+)\)$/\1/p')" \
  sidTS=$(( ts / 60 - 27875460 )); sidTS="$(int2b58 $sidTS)"
  test "$pr" || pr="${PULL_NUMBER:-0}"
  # echo "$ts $author [$pr] $msg"
  # 58 ** 2 = 3364
  authorHash=$((
    $(hex2decimal $(printf "$author" | md5sum | head -c3))
    % 3364
  )); authorHash="$(int2b58 $authorHash )"
  rawSID="$sidTS$authorHash"
  test $pr -gt 0 && rawSID="$rawSID$(echo "$pr" | sed -E 's/^0+//')"
  sidCheckDigit=$((
    $(hex2decimal $(printf -- "$rawSID" | md5sum | head -c2))
    % 58
  )); sidCheckDigit="$(int2b58 $sidCheckDigit )"
  printf '%4s%2s%s' \
    "$sidTS" "$authorHash" "$sidCheckDigit" \
    | tr ' ' '0'
  test $pr -gt 0 && printf '.%03d' \
    "$pr"
  echo
}

# Given a SID, returns True if the computed checksum is the same as the SID-embedded checksum.
validate_sid_checksum() {
  local sid="$1"; shift
  IFS=. read tsc ah pr <<<"$sid"
  tsc="$(echo "$tsc" | tr 'IOlo' '1010')"
  ah="$(echo "$ah" | tr 'IOlo' '1010')"
  local pr="$(echo "$pr" | sed -E 's/^0+//')"
  local rawSID="$(echo "${tsc:0:-1}" | tr 'IOlo' '1010' | sed -E 's/^0+//')$ah$pr"
  local expected_checksum="$((
    $(hex2decimal $(printf "$rawSID" | md5sum | head -c2))
    % 58
  ))"

  test "$(int2b58 $expected_checksum)" == "${tsc: -1}"
}

tid() {
  local ts="$1" msg="$2"
  local pr="$(echo "$msg" | sed -En 's/.*\(#([0-9]+)\)$/\1/p')"
  test "$pr" || pr="${PULL_NUMBER:-0}"
  test "$TID_TIME_FORMAT" || TID_TIME_FORMAT="%y.%j.%H%M"
  test "$TID_SHORT" && TID_TIME_FORMAT="${TID_TIME_FORMAT//./}"
  local tidTS=$(date --utc --date "@$ts" +"$TID_TIME_FORMAT")
  # echo "$ts $author [$pr] $msg"
  printf '%s%s' \
    "${TID_PREFIX:+"$(echo "$TID_PREFIX" | tr '[:upper:]' '[:lower:]')"-}" \
    "$tidTS" \
    | tr ' ' '0'
  test $pr -gt 0 -a -z "$TID_OMIT_PR" && printf -- '-%04d' "$pr"
  echo
}
