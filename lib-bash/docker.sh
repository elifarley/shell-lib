docker_image_exists() {
  local image_full_name="$1"; shift
  local wait_time="${1:-5}"
  local search_term='Pulling|is up to date|not found'
  local result="$((timeout --preserve-status "$wait_time" docker 2>&1 pull "$image_full_name" &) | grep -v 'Pulling repository' | egrep -o "$search_term")"
  test "$result" || { echo "Timed out too soon. Try using a wait_time greater than $wait_time..."; return 1 ;}
  echo $result | grep -vq 'not found'
}
