# shellcheck shell=dash
curlGithubRaw() (set +x
  # $1: path. Example: project/master/values.yaml
  # $2: company. If absent, $GH_COMPANY
  gh_path="$1"; shift
  test "${gh_path:?}" || return
  gh_path="${2:-${GH_COMPANY:?}}/$gh_path"
  echo >&2 "[curlGithubRaw] Path: '$gh_path'"
  curl -LSs https://x-access-token:"${GITHUB_OAUTH_TOKEN:?}@raw.githubusercontent.com/$gh_path" \
  || {
    printf >&2 '[curlGithubRaw] ERROR! GITHUB_OAUTH_TOKEN sha256: %s\n' "$(printSecret "$GITHUB_OAUTH_TOKEN")"
    return 1
  }
)

curlGithub() (
  type="$1" path="$2" curlOpts=''
  test $# -gt 0 && shift
  test $# -gt 0 && shift
  test "$APP_REVISION" || APP_REVISION="${PULL_PULL_SHA:-$PULL_BASE_SHA}"
  test "${APP_REVISION:?'Missing app revision'}"
  ghUrl=https://api.github.com/repos/"${REPO_OWNER:-deliveryhero}/${REPO_NAME:?'Missing value'}/${type:?'Missing value'}/$(
    test "$type" = issues && echo "${PULL_NUMBER:?'Missing value'}" || echo "$APP_REVISION"
  )$path"
  set +x;
  # test "$DEBUG" && curlOpts='-i'
  test "$DEBUG" && echo >&2 "ghUrl: $ghUrl"
  curl $curlOpts -LSs --fail-with-body "$@" -H "Authorization: token ${GITHUB_OAUTH_TOKEN:?'Missing value'}" -H "Accept: application/$(
    test "$type" = pulls || echo 'vnd.github.v3+'
  )json" \
  "$ghUrl"
)

github_ref() (
  test "$1" && APP_REVISION="$1" && shift
  test "${APP_REVISION:?'[github_ref] Missing value'}"
  echo >&2 "[github_ref] Repo: ${REPO_OWNER:-no owner}/${REPO_NAME:-no name}"
  commit_message="$( git show -s --format='%s' "$APP_REVISION" )" \
    || {
      commit_message="$( curlGithub commits )" \
      && commit_message="$( set +x; echo "$commit_message" | jq -r '.commit?.message? | select( . != null )' | head -1 )" \
      || {
        echo >&2 "[github_ref] Failed to parse commit message: [$commit_message]"
        return 1
      }
    }
  test "${commit_message:?'[github_ref] Not found'}"
  PULL_NUMBER_IN_COMMENT="$(echo "$commit_message" | sed -En 's/^[^(]+[(]#([0-9]+)[)]$/\1/gp')"
  PULL_NUMBER="${PULL_NUMBER//[!0-9]/}"
  test "$PULL_NUMBER" || PULL_NUMBER="$PULL_NUMBER_IN_COMMENT"
  test "$PULL_NUMBER" || {
    echo >&2 "[github_ref] APP_REVISION: $APP_REVISION; PULL_NUMBER: ?"
    link_suffix="commit/$APP_REVISION|commit ${APP_REVISION:0:6}>"
  }
  test "$PULL_NUMBER" && {
    echo >&2 "[github_ref] APP_REVISION: $APP_REVISION; PULL_NUMBER: $PULL_NUMBER"
    issues_obj="$(DEBUG=1 curlGithub issues || echo >&2 '[github_ref] curlGithub call failed.')" \
    && pr_title="$(set +x; echo "$issues_obj" | jq -r '.title? | select( . != null )')"
    test "$pr_title" \
      || echo >&2 "[github_ref] PR title not found. issues_obj: --|${issues_obj}|--"
    link_suffix="pull/$PULL_NUMBER|PR #$PULL_NUMBER>${pr_title:+:\n*"$pr_title*"}"
  }
  echo "<https://github.com/${REPO_OWNER:-deliveryhero}/${REPO_NAME:-'?REPO_NAME?'}/$link_suffix"
  # Avoid repeating the same message
  test "$PULL_NUMBER_IN_COMMENT" || echo "\n>$commit_message"
)

github_get_pull_number() (
  github_ref "$1" 2>/dev/null | sed -En 's;^.+/pull/([0-9]+)[^0-9].+$;\1;p'
)

github_get_commit_status_url() (
  test "$1" && COMMIT_CONTEXT="$1" && shift
  curlGithub statuses '' -H 'X-GitHub-Api-Version: 2022-11-28' \
  | jq -r '.[] | select(.context == "'${COMMIT_CONTEXT:?'[github_get_commit_status] No value'}'") | .target_url | select( . != null )'
)

github_set_commit_status() (
  # Possible values for state: error, failure, pending, success
  COMMIT_STATE="$1" COMMIT_DESCRIPTION="$2" COMMIT_TARGET_URL="$3"
  curlGithub statuses '' -H 'X-GitHub-Api-Version: 2022-11-28' -XPOST -d@- <<EOF
{
  "state":"${COMMIT_STATE:?'[github_set_commit_status] Missing value'}",
  "description":"$COMMIT_DESCRIPTION",
  "target_url":"$COMMIT_TARGET_URL",
  "context":"${COMMIT_CONTEXT:?'[github_set_commit_status] Missing value'}"
}
EOF
)
