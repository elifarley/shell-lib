# shellcheck shell=dash
curlGithubRaw() (set +x
  # $1: path. Example: <user>/<repo>/<branch>/path/to/file.txt
  # $2: GitHub token 
  local github_path="$1" github_token="$2"
  echo >&2 "[curlGithubRaw] Path: '$github_path'"
  curl -LSs https://${github_token:+x-access-token:"$github_token"}@raw.githubusercontent.com/"$github_path"
)
