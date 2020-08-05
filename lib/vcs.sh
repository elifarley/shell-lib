changeset() {
  echo "${GIT_COMMIT:-${MERCURIAL_REVISION:-$(
    test -d "$1" && cd "$1"
    test -d .git && git 2>/dev/null rev-parse HEAD \
      && return
    test -d .hg && hg log -r . --template '{node}\n'
  )}}"
}

vcs_url() {
  echo "${GIT_URL:-$(
    test -d "$1" && cd "$1"
    test -d .git && git 2>/dev/null remote get-url origin \
      && return
    test -d .hg && echo "$(hg paths | head -n1 | cut -d= -f2)"
  )}"
}

changeset_short() {
  printf '%.7s' "${1:-"$(changeset)"}"
}
