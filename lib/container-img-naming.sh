#@IgnoreInspection BashAddShebang
userAtHost() {
  echo $(id -nu)-at-$(hostname -s)
}

CONTAINER_PROPERTIES_PATH=''

update_container_props_path() {
  test -s "$CONTAINER_PROPERTIES_PATH" && return
  CONTAINER_PROPERTIES_PATH="$(find .. . -maxdepth 1 -name container.properties)"
  test "$CONTAINER_PROPERTIES_PATH" || CONTAINER_PROPERTIES_PATH=container.properties
}

getprop_container() {
  local cprops="$CONTAINER_PROPERTIES_PATH"
  test -s "$cprops" && getprop "$cprops" "$1" && return
  test "$2" || return
  cprops="${cprops:-container.properties}"
  local val="$(eval echo $2)"
  echo $1=$val >> "$cprops" && echo $val
}

set_img_vars() {
  test $# -ge 2 || {
    printf 'Parameters:\n\nIMG_NAME\n<BUILD_NUMBER>\n<CHANGESET>\nIMG_REPO'
    return 1
  }

  update_container_props_path

  local IMG_NAME="${1:-$JOB_NAME}"; test $# -gt 0 && shift
  IMG_NAME="$(echo $(getprop_container IMG_NAME '$IMG_NAME') | tr '/ ' '.-')"

  local IMG_BUILD_NUMBER="${1:-$BUILD_NUMBER}"; test $# -gt 0 && shift
  IMG_BUILD_NUMBER="$(getprop_container IMG_BUILD_NUMBER '${IMG_BUILD_NUMBER:-$(userAtHost)}')"
  IMG_BUILD_NUMBER="$(echo "$IMG_BUILD_NUMBER" | tr '/ ' '.-')"

  local IMG_CHANGESET="${1:-$CHANGESET}"; test $# -gt 0 && shift
  IMG_CHANGESET="$(getprop_container IMG_CHANGESET '${IMG_CHANGESET:-$(changeset)}')"
  IMG_CHANGESET="$(echo "$IMG_CHANGESET" | tr '/ ' '.-')"

  local IMG_REPO="$(echo ${1:-$IMG_REPO})"
  IMG_REPO="${IMG_REPO:-$(getprop_container IMG_REPO)}"
  IMG_REPO="$(echo $IMG_REPO | tr ' ' '-')"
  test "$IMG_REPO" || {
    cat <<-EOF 1>&2
ERROR: "\$IMG_REPO" is empty. You can also create a file named 'container.properties' with content like this:
IMG_REPO=mycompany/my-repo
EOF
 return 0
  }

  IMG_PREFIX_BASE="$(echo $IMG_REPO:$IMG_NAME | tr '[:upper:]' '[:lower:]')."
  IMG_PREFIX_BN="$(echo ${IMG_PREFIX_BASE}$IMG_BUILD_NUMBER | tr '[:upper:]' '[:lower:]')"
  IMG_PREFIX_CS="$IMG_PREFIX_BN-$(changeset_short "$IMG_CHANGESET")"
}
