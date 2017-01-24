userAtHost() {
  echo $(id -nu)-at-$(hostname -s)
}

changeset() {
  echo "${GIT_COMMIT:-$(if test -d "$1"; then cd "$1"; fi; git 2>/dev/null rev-parse HEAD)}"
}

changeset_short() {
  printf '%.7s' "${1:-$(changeset)}"
}

set_img_vars() {
  test $# -ge 2 || {
    printf 'Parameters:\n\nIMG_REPO\nJOB_NAME\n<BUILD_NUMBER>\n<CHANGESET>'
    return 1
  }

  local IMG_REPO="$(echo ${1:-$IMG_REPO} | tr '[:upper:]' '[:lower:]')"; test $# -gt 0 && shift
  local IMG_JOB_NAME="$(echo "${1:-$JOB_NAME}" | tr '/' '.')"; test $# -gt 0 && shift
  local IMG_BUILD_NUMBER="${1:-${BUILD_NUMBER:-$(userAtHost)}}"; test $# -gt 0 && shift
  local CHANGESET="${1:-${GIT_COMMIT:-$(chageset)}}"
  
  IMG_PREFIX_BASE="$(echo $IMG_REPO:$IMG_JOB_NAME | tr '[:upper:]' '[:lower:]')."
  IMG_PREFIX_BN="$(echo ${IMG_PREFIX_BASE}$IMG_BUILD_NUMBER | tr '[:upper:]' '[:lower:]')"
  IMG_PREFIX_CS="$IMG_PREFIX_BN-$(changeset_short "$CHANGESET")"
}
