userAtHost() {
  echo $(id -nu)-at-$(hostname -s)
}

chageset() {
  git 2>/dev/null rev-parse HEAD
}

changeset_short() {
  printf '%.7s' "${1:-$(chageset)}"
}

set_img_vars() {
  test $# -ge 2 || {
    printf 'Parameters:\n\nIMG_REPO\nUJOB_NAME\n<BUILD_NUMBER>\n<CHANGESET>'
    return 1
  }

  local IMG_REPO="$(echo $1 | tr '[:upper:]' '[:lower:]')"; shift
  local IMG_JOB_NAME="$1"; test $# -gt 0 && shift
  local IMG_BUILD_NUMBER="${1:-$(userAtHost)}"; test $# -gt 0 && shift
  local CHANGESET="${1:-$(chageset)}"
  
  IMG_PREFIX_BASE="$(echo $IMG_REPO:$IMG_JOB_NAME | tr '[:upper:]' '[:lower:]')."
  IMG_PREFIX_BN="$(echo ${IMG_PREFIX_BASE}$IMG_BUILD_NUMBER | tr '[:upper:]' '[:lower:]')"
  IMG_PREFIX_CS="$IMG_PREFIX_BN-$(changeset_short "$CHANGESET")"
}
