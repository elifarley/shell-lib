userAtHost() {
  echo $(id -nu)-at-$(hostname -s)
}

getprop_container() {
  local cprops="$(find .. . -maxdepth 1 -name container.properties)"
  test "$cprops" -a -s "$cprops" && \
    getprop "$cprops" "$1"
}

set_img_vars() {
  test $# -ge 2 || {
    printf 'Parameters:\n\nIMG_REPO\nIMG_NAME\n<BUILD_NUMBER>\n<CHANGESET>'
    return 1
  }

  local IMG_REPO="$(echo ${1:-$IMG_REPO})"; test $# -gt 0 && shift
  IMG_REPO="${IMG_REPO:-$(getprop_container IMG_REPO)}"
  IMG_REPO="$(echo $IMG_REPO | tr ' ' '-')"
  test "$IMG_REPO" || {
    cat <<-EOF
ERROR: "\$IMG_REPO" is empty. You can also create a file named 'container.properties' with content like this:
IMG_REPO=mycompany/my-repo
EOF
 return 0
  }

  local IMG_NAME="$(echo "${1:-$JOB_NAME}" | tr '/ ' '.-')"; test $# -gt 0 && shift
  local IMG_BUILD_NUMBER="$(echo ${1:-${BUILD_NUMBER:-$(userAtHost)}} | tr '/ ' '.-' )"; test $# -gt 0 && shift
  local CHANGESET="${1:-$(chageset)}"

  IMG_PREFIX_BASE="$(echo $IMG_REPO:$IMG_NAME | tr '[:upper:]' '[:lower:]')."
  IMG_PREFIX_BN="$(echo ${IMG_PREFIX_BASE}$IMG_BUILD_NUMBER | tr '[:upper:]' '[:lower:]')"
  IMG_PREFIX_CS="$IMG_PREFIX_BN-$(changeset_short "$CHANGESET")"
}
