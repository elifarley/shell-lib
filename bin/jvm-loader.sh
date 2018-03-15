#!/bin/sh
# See https://wiki.apache.org/tomcat/HowTo/FasterStartUp#Entropy_Source

jvm_loader() {
  local project_root
  local count
  local app_exec

  test "$1" -a "$1" != '--' && project_root="$1" || project_root="$PWD"
  shift

  echo "[jvm_loader] App root: '$project_root'"

  # Single jar
  count="$(find "$project_root"/ -name '*app.jar' | wc -l)"
  test $count -eq 1 && {
    app_exec="$(find "$project_root"/ -name '*app.jar')"
    echo "[jvm_loader] Loading single jar: '$app_exec'..."
    # See http://www.2uo.de/myths-about-urandom/
    exec java \
    -Djava.security.egd=file:/dev/./urandom \
    -jar "$app_exec" "$@" || return
  }

  test $count -gt 1 && {
    echo "[jvm_loader] More than 1 jar found at '$project_root':"
    ls -lhFa "$project_root"/*app.jar
    return 1
  }

  # Gradle
  count="$(find "$project_root"/bin/ -mindepth 1 ! -type d ! -name '*.*' | wc -l)"
  test $count -eq 1 && {
    app_exec="$(find "$project_root"/bin/ -mindepth 1 ! -type d ! -name '*.*')"
    echo "[jvm_loader] Loading Gradle-based app: '$app_exec'..."
    test -x "$app_exec" || chmod u+x "$app_exec"
    exec "$app_exec" "$@" || return
  }

  test $count -gt 1 && {
    echo "[jvm_loader] More than 1 executable found at '$project_root/bin':"
    find "$project_root"/bin/ -mindepth 1 ! -type d ! -name '*.*' -exec ls -lhFa {} +
    return 1
  }

  echo "Unable to find Java application at '$project_root'. Aborting."
  return 1
}

test "$DEBUG" && set -x
jvm_loader "$@"
