yaml_lines() {
  local root_key="${1:-\S+}" line_prefix="${2:-[a-zA-Z]*}"
  sed -En '/^'"$root_key"':/{:loop n; s!^\s*'"$line_prefix"'[^:]+:[ "]*([^"]+)"!\1!p; /^\S+:/q; b loop}'
}
