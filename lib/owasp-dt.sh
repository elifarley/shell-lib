# dt_get_project_uuid my-demo argo:??/my-demo
# Requires permission VIEW_PORTFOLIO
dt_get_project_uuid() {
  test "$#" = 2 || return
  local projectName="$1" projectVersion="$2" resp
  resp=$(
    curl --fail-with-body -LSs -H "X-Api-Key: ${DT_API_KEY?}" \
    -G -d name="$projectName" -d version="$projectVersion" \
    "$DT_API_URL/project/lookup"
  ) && \
  echo "$resp" | jq -er '.uuid' 2>/dev/null && \
  return
  printf >&2 '### ERROR getting UUID (%s @ %s): %s\n' \
    "$projectName" "$projectVersion" "$resp"
  return 1
}

dt_download_sbom() {
  local projectName="$1" projectVersion="$2" projectUUID
  shift; shift
  projectUUID=$(dt_get_project_uuid "$projectName" "$projectVersion") || {
    echo "### ERROR [$projectName @ $projectVersion] Download SBOM"
    return 1
  }
  curl --fail-with-body -LSs -H "X-Api-Key: ${DT_API_KEY?}" \
  -G -d format=json -d variant=inventory -d download=true \
  "$DT_API_URL/bom/cyclonedx/project/$projectUUID"
}

dt_set_metadata() {
  local projectName="$1" projectVersion="$2" imageTag="$3" isExternal="$4" \
  projectUUID
  shift; shift; shift; shift
  test ! $# = 6 && \
  echo "Usage: dt_set_metadata <projectName> <projectVersion> <imageTag> <isExternal> <appCreated> <slug> <env> <OAM context> <destination> <proj>" && return 1
  local app_created="$1"; shift;
  local slug="$1"; shift
  local environment="$1"; shift
  local oam_ctx="$1"; shift
  local dest="$1"; shift
  local proj="$1"; shift

  projectUUID=$(dt_get_project_uuid "$projectName" "$projectVersion") || {
    echo "### ERROR [$projectName @ $projectVersion] Get project UUID"
    return 1
  }

  dt_set_tags "$projectName" "$projectVersion" "$projectUUID" "$isExternal" \
  "$app_created" "$slug" "$environment" "$oam_ctx" "$dest" "$proj" || {
    echo "### ERROR [$projectName @ $projectVersion] Tagging"
  }

  dt_set_property "$projectUUID" "image" tag "$imageTag" || {
    echo "### ERROR [$projectName @ $projectVersion] Property"
    return 1
  }

}

# Requires permissin PORTFOLIO_MANAGEMENT
dt_set_tags() {
  local projectName="$1" projectVersion="$2" projectUUID="$3" squad
  shift; shift; shift
  local isExternal="$1"; shift;
  local app_created="$1"; shift;
  local slug="$1"; shift
  local environment="$1"; shift
  local oam_ctx="$1"; shift
  local dest="$1"; shift
  local proj="$1"; shift
  app_created=$(echo "$app_created" | cut -c1-7)
  squad="$(echo "$projectVersion" | grep -Eo ':[^/]+/' | tr -d ':/' )"

  local tagt='{"name":"%s:%s"}' tags=''
  tags="$tags${isExternal:+,$(printf "$tagt" external 'true')}"
  tags="$tags${squad:+,$(printf "$tagt" squad "$squad")}"
  tags="$tags${app_created:+,$(printf "$tagt" created "$app_created")}"
  tags="$tags${slug:+,$(printf "$tagt" slug "$slug")}"
  tags="$tags${environment:+,$(printf "$tagt" env "$environment")}"
  tags="$tags${oam_ctx:+,$(printf "$tagt" oamctx "${oam_ctx%.y*}")}"
  tags="$tags${dest:+,$(printf "$tagt" dest "$dest")}"
  tags="$tags${proj:+,$(printf "$tagt" proj "$proj")}"
  tags="$(echo "$tags" | cut -c2-)"
  curl <<EOF -o /dev/null -d@- --fail-with-body -LSs \
  -H 'Content-Type: application/json' -H "X-Api-Key: ${DT_API_KEY?}" \
  "$DT_API_URL/project"
{"uuid":"$projectUUID","name":"$projectName","version":"$projectVersion",
"classifier":"CONTAINER", "tags":[$tags]}
EOF
}

# Requires permission PORTFOLIO_MANAGEMENT
dt_set_property() {
  test $# -ge 4 || return
  local projectUUID="$1" groupName="$2" key="$3" value="$4" \
    propType="${5:-STRING}" resp
  resp="$(
    _dt_set_property PUT "$projectUUID" "$groupName" "$key" "$value" "$propType"
  )" && return

  if test "$resp" = 409; then
    # Property already existed, so let's just update it
    resp="$(
      _dt_set_property POST "$projectUUID" "$groupName" "$key" "$value" "$propType"
    )" && return
  fi
  echo 2>&2 "### [dt_set_property] HTTP status '$resp' for args:" $@
  return 1
}

_dt_set_property() {
  test $# = 6 || return
  local method="$1"; shift
  local projectUUID="$1" groupName="$2" key="$3" value="$4" propType="$5"
  curl -X$method <<EOF 2>/dev/null -o /dev/null -d@- --fail-with-body -LSs \
  -w "%{http_code}\n" \
  -H 'Content-Type: application/json' -H "X-Api-Key: ${DT_API_KEY?}" \
  "$DT_API_URL/project/$projectUUID/property"
{"groupName": "$groupName","propertyType": "$propType",
"propertyName": "$key","propertyValue": "$value"}
EOF
}

dt_imagespec2projectName() {
  local imagespec="$1" result; shift
  # Check if the repository is in amazonaws.com
  # and remove the repository DNS part
  result=$( echo "${imagespec%%:*}" | tr '[:upper:]' '[:lower:]')
  echo "$result" | grep -q amazonaws\.com && \
    result="${result#*/}"
  echo "$result"
}

syft_generate_image_sbom() {
  local imagespec="$1"; shift
  syft -o cyclonedx-json packages docker:"$imagespec" \
  | jq -S
}
trivy_generate_image_sbom() {
  local imagespec="$1"; shift
  docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/tmp/cache-trivy:/root/.cache \
  aquasec/trivy:0.47.0 -q image --format cyclonedx "$imagespec" \
  | jq -S
}

sbom_merge() (
  local out="$1"; shift
  sbomMerger.py "$@" >"$out"
)

generate_image_sbom() {
  local sbom_temp="$1" imagespec="$2" projectName="$3" projectVersion="$4"
  rm -f "$sbom_temp".json "$sbom_temp".syft.json "$sbom_temp".trivy.json

  if ! docker pull -q "$imagespec" >/dev/null; then
    docker pull "$imagespec" >&2 && \
      echo "### ERROR [$projectName @ $projectVersion] Pull worked only at the second attempt for $imagespec" && \
      return 2
    echo "### ERROR [$projectName @ $projectVersion] Docker pull '$imagespec'"
    return 3
  fi

  syft_generate_image_sbom "$imagespec" >"$sbom_temp".syft.json || {
    echo "### ERROR [$projectName @ $projectVersion] Syft"
    return 1
  }
  test -s "$sbom_temp".syft.json || {
    echo "### ERROR [$projectName @ $projectVersion] Syft output is empty"
    return 4
  }

  trivy_generate_image_sbom "$imagespec" >"$sbom_temp".trivy.json || {
    echo "### ERROR [$projectName @ $projectVersion] Trivy"
    return 1
  }
  test -s "$sbom_temp".trivy.json || {
    echo "### ERROR [$projectName @ $projectVersion] Trivy output is empty"
    return 4
  }
}

generate_image_sbom_merged() {
  local sbom_temp="$1" imagespec="$2" projectName="$3" projectVersion="$4"
  generate_image_sbom "$sbom_temp" "$imagespec" "$projectName" "$projectVersion"

  sbom_merge "$sbom_temp".json "$sbom_temp".syft.json "$sbom_temp".trivy.json || {
    echo "### ERROR [$projectName @ $projectVersion] SBOM Merge"
    return 1
  }
  test -s "$sbom_temp".json || {
    echo "### ERROR [$projectName @ $projectVersion] SBOM merge output is empty"
    return 4
  }

  rm "$sbom_temp".*.json
}

# dt_upload_from_image "$imagespec" "$projectVersion"
_dt_upload_from_image_previous_imagespec='' # Helps cache SBOM contents
dt_upload_from_image() {
  local imagespec="$1" projectVersion="$2" \
  sbom_temp="${3:-/tmp/upload-cyclonedx}" projectName

  # Check if the repository is in amazonaws.com
  # and remove the repository DNS part
  projectName="$(dt_imagespec2projectName "$imagespec")"

  cached_imagespec="## CACHED: $imagespec --> $projectVersion"
  test ! -s "$sbom_temp".json -o \
    "$imagespec" != "$_dt_upload_from_image_previous_imagespec" && {
    cached_imagespec=''
    generate_image_sbom_merged "$sbom_temp" "$imagespec" \
      "$projectName" "$projectVersion"  || return

    # docker image rm "$imagespec" 2>/dev/null 1>&2 ||:
  } # It was a new imagespec

  test "$cached_imagespec" && echo "$cached_imagespec"
  _dt_upload_from_image_previous_imagespec="$imagespec"
  dt_upload_sbom "$projectName" "$projectVersion" "$sbom_temp".json
}

dt_upload_sbom() {
  local projectName="$1" projectVersion="$2" sbom_temp="$3" token
  token="$(
    curl --fail-with-body -LSs -X POST "$DT_API_URL"/bom \
     -H 'Content-Type: multipart/form-data' \
     -H "X-Api-Key: ${DT_API_KEY?}" \
     -F "autoCreate=true" \
     -F "projectName=$projectName" \
     -F "projectVersion=$projectVersion" \
     -F "bom=@$sbom_temp"
  )" || {
    echo "### ERROR [$projectName @ $projectVersion] Upload"
    return 5
  }
  # We could show the processing status of the sbom upload:
  # curl "$DT_API_URL/bom/token/$token" -H "X-Api-Key: ${DT_API_KEY?}"
  echo "$token" | grep -q token || {
    echo "### ERROR [$projectName @ $projectVersion] Upload token: '$token'"
    return 6
  }
}
####

# dt_vuln_per_project "$projectName" argo:"$app_slug" "$imageTag"
# Requires permission VIEW_VULNERABILITY
dt_vuln_per_project() {
  test -z "$1" -o $# -lt 2 && echo "dt_vuln_per_project <name> <version> <image-tag>" && return 1

  local projectName="$1" projectVersion="${2?}" imageTag="$3"
  local projectUUID resp csvContent \
  prefix="$projectName,$projectVersion,$imageTag,"
  projectUUID=$(dt_get_project_uuid "$projectName" "$projectVersion") \
    || return

  # Fetch vulnerabilities for the project
  resp=$(
    curl --fail-with-body -LSs -H "X-Api-Key: ${DT_API_KEY?}" \
    "$DT_API_URL/finding/project/$projectUUID"
  ) && \
  csvContent=$(printf '%s' "$resp" | \
      jq -r '.[] | [.vulnerability.vulnId, .vulnerability.severity, .vulnerability.cvssV3BaseScore] | @csv'
  ) && \
  printf '%s' "$csvContent" | \
  tr -d '"' | LC_NUMERIC=C sort -u -t, -k 2,2 -k 3,3gr -k1,1 | \
  awk '{print "'"$prefix"'" $0}' && \
  return
  printf >&2 '[dt_vuln_per_project] %s' "$(printf '%s' "$resp$csvContent" | head -c100)"
  return 1
}

dt_components_per_project() {
  test -z "$1" -o $# -lt 2 && echo "dt_components_per_project <name> <version> <image-tag>" && return 1

  local projectName="$1" projectVersion="${2?}"
  local projectUUID resp csvContent \
  prefix=""
  projectUUID=$(dt_get_project_uuid "$projectName" "$projectVersion") \
    || return

  # Fetch vulnerabilities for the project
  resp=$(
    curl --fail-with-body -LSs -H "X-Api-Key: ${DT_API_KEY?}" \
    "$DT_API_URL/finding/project/$projectUUID"
  ) && \
  csvContent=$(printf '%s' "$resp" | \
      jq -r '.[] | .component.purl'
  ) && \
  printf '%s' "$csvContent" | \
  tr -d '"' | LC_NUMERIC=C sort -u | \
  awk '{print "'"$prefix"'" $0}' && \
  return
  printf >&2 '[dt_vuln_per_project] %s' "$(printf '%s' "$resp$csvContent" | head -c100)"
  return 1
}

count_severity_by_squad() { awk -F, '
  $5 == "CRITICAL" || $5 == "HIGH" {
    squad = "NO_SQUAD" # Default to NO_SQUAD if no squad name is found
    # Split the second field by ":" and take the second part
    n = split($2, parts, ":")
    if (n > 1) {
      # Further split by "/" to isolate the squad name
      split(parts[2], squad_parts, "/")
      squad = squad_parts[1]
    }
    # Increment the count for the squad
    counts[squad]++
  }
  END {
    # Output the results
    for (squad in counts) {
      print squad ": " counts[squad]
    }

  }
' | sort -t: -k1,1
}
