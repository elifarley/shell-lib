changeset() {
  echo "${GIT_COMMIT:-${MERCURIAL_REVISION:-$(
    if test -d "$1"; then cd "$1"; fi
    test -d .git && git 2>/dev/null rev-parse HEAD \
    || \
    test -d .hg && hg log -r . --template '{node}\n'
  )}}"
}

vcs_url() {
  echo "${GIT_URL:-$(
    if test -d "$1"; then cd "$1"; fi
    test -d .git && git 2>/dev/null remote get-url origin \
    || \
    test -d .hg && echo $(hg paths | head -n1 | cut -d= -f2)
  )}"
}

changeset_short() {
  printf '%.7s' "${1:-$(changeset)}"
}
