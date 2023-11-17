argocd() (
  ARGOCD_OPTS="${ARGOCD_OPTS:---grpc-web}"
  command argocd $ARGOCD_OPTS $ARGO_ARGS --http-retry-max 5 "$@"
)

# Fetch the list of application names from ArgoCD;
argocd_app_list_names() {
  argocd app list -o name ${ARGO_APP_ENV:+-l environment=$ARGO_APP_ENV} \
  | sort -u
}

# Loop through each application name and print its image list
list_images_per_app() ( while read -r argo_app; do
  # The list of images usually come from:
  # - .metadata.summary.images
  # -   .status.summary.images
  # Tip: use jq -r 'paths | select(.[-1] == "images")'
  argo_app_json="$(
    argocd app get "$argo_app" -o json --loglevel error \
    | jq -r '{
creationTimestamp: .metadata.creationTimestamp,
repoURL: .spec.source.repoURL,
environment: .metadata.labels.environment,
squad: .metadata.labels.squad,
oamctx: ((.spec.source.plugin.env // [] | map(select(.name=="CONTEXT")) | .[0].value) // null),
destination: .spec.destination.name,
project: .spec.project,
images: [.. | objects | select(has("images")) | .images[]]
}'
  )"

  test -z "$argo_app_json" && \
    echo >&2 "### Error for $argo_app" && continue

  app_slug="$(echo "$argo_app_json" | jq -r '.squad // ""')"
  app_slug="${app_slug:+$app_slug/}${argo_app#cicd-platform/}"

  # Print 1 row for Argo app details
  printf "#%s," "$app_slug"
  echo "$argo_app_json" | jq -er \
  '. | del(.images) | del(.squad) | [to_entries[] | .value] | @csv' | tr -d '"'

  # Print 1 row for each image in the app
  echo "$argo_app_json" | jq -r '.images[]' | sort -u
done )

# Transform images-per-app into apps-per-image
as_apps_per_image() {
  echo 'image,image_tag,app_slug,app_created,slug,environment,oamctx,destination,project'

  awk '/^#/{header=substr($0, 2)} !/^#/ && NF>0{split($0, a, ":"); print a[1] "," a[2] "," header}' | \
  sed -E '
s!,[^:]+://github.com/([^,]+)\.git,!,\1,!
s!,[^:]+://github.com/([^,]*),!,\1,!
' | \
  sort -u
}
