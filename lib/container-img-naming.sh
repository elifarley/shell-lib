userAtHost() {
  echo $(id -nu)-at-$(hostname -s)
}

chageset() {
  git rev-parse HEAD
}

changeset_short() {
  printf '%.7s' "${1:-$(chageset)}"
}

IMG_PREFIX_BASE="$(echo $IMG_REPO:$IMG_JOB_NAME | tr '[:upper:]' '[:lower:]')."
IMG_PREFIX_BN="$(echo ${IMG_PREFIX_BASE}$IMG_BUILD_NUMBER | tr '[:upper:]' '[:lower:]')"
IMG_PREFIX_CS="$REPO_PREFIX_BN-$(changeset_short "$CHANGESET")"
