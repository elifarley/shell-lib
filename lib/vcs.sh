changeset() {
  echo "${GIT_COMMIT:-$(if test -d "$1"; then cd "$1"; fi; git 2>/dev/null rev-parse HEAD)}"
}

changeset_short() {
  printf '%.7s' "${1:-$(changeset)}"
}
