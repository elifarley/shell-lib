#!/bin/sh
# See https://wiki.apache.org/tomcat/HowTo/FasterStartUp#Entropy_Source

jvm_loader() {
  local project_root="${1:-$PWD}"
  local count

  # Single jar
  count="$(find "$project_root" -name '*app.jar' | wc -l)"
  test $count -eq 1 && {
    exec java \
    -Djava.security.egd=file:/dev/./urandom \
    -jar "$project_root"/*app.jar "$@" || return
  }

  test $count -gt 1 && {
    echo "More than 1 jar found at '$project_root':"
    ls -lhFart "$project_root"/*app.jar
    return 1
  }

  # Gradle
  count="$(find "$project_root"/bin ! -name '*.*' | wc -l)"
  test $count -eq 1 && {
    local app_exec
    app_exec="$(find "$project_root"/bin ! -name '*.*')" && \
    { test -x "$app_exec" || chmod u+x "$app_exec" ;} && \
    exec "$app_exec" "$@" || return
  }

  test $count -gt 1 && {
    echo "More than 1 executable found at '$project_root/bin':"
    find "$project_root"/bin ! -name '*.*' -exec ls -lhFart {} +
    return 1
  }

  echo "Unable to find Java application at '$project_root'. Aborting."
  return 1
}

jvm_loader "$@"
