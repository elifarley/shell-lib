#!/bin/sh

default_cert_import_dir="${default_cert_import_dir:-/mnt-ssh-config/certs}"
default_keystore="${default_keystore:-"$JAVA_HOME"/jre/lib/security/cacerts}"

keytool_import_certs() {
  local cert_import_dir=''
  local force=''; test "$1" = '--force' -o "$1" = '-f' && {
    force=1; test $# -gt 0 && shift && cert_import_dir="$1"
  }
  test "$cert_import_dir" = '--' && cert_import_dir=''
  cert_import_dir="${cert_import_dir:-$default_cert_import_dir}"
  local storepass="${2:-changeit}"
  local keystore="${3:-$default_keystore}"

  test -d "$cert_import_dir" && test "$(ls -A "$cert_import_dir" 2>/dev/null)" || {
    echo "No certificates to import from '$cert_import_dir'"
    return 1
  }

  echo "Importing certificates from '$cert_import_dir' into '$keystore'"
  local v
  local count=0
  for cert in "$cert_import_dir"/*; do
    # Find out if alias already exists
    keytool 2>/dev/null >/dev/null -list -alias "$(basename "$cert")" -noprompt -storepass "$storepass" \
    -keystore "$keystore" && {
      test -z "$force" && \
        v='Skipping existing item' && \
        printf '%s "%s"...\n' "$v" "$(basename "$cert")" && \
        continue
      v='Re-importing'
      keytool 2>/dev/null >/dev/null -delete -alias "$(basename "$cert")" -noprompt -storepass "$storepass" \
        -keystore "$keystore" || return
    } || v='Importing'
    printf '%s "%s"...\n' "$v" "$(basename "$cert")"
    keytool 2>&1 -import -file "$cert" -alias "$(basename "$cert")" -noprompt -storepass "$storepass" \
    -keystore "$keystore" | grep -v JAVA_TOOL_OPTIONS || return
    count=$((count + 1))
  done

  v="$count certificate"; test $count -gt 1 && v="${v}s"
  echo "$v imported."
}

keytool_import_certs_interactive() {

  cert_import_dir="$1"; storepass="$2"; keystore="$3"

  test "$cert_import_dir" || \
    read -p "Path to directory with certificates to import ($default_cert_import_dir): " cert_import_dir

  test "$storepass" || \
    read -p 'Type the store password (changeit): ' storepass

  test "$keystore" || \
    read -p "Path to the key store ($default_keystore): " keystore

  keytool_import_certs "$cert_import_dir" "$storepass" "$keystore"
}

test $# -gt 0 && { keytool_import_certs "$@"; return ;}

keytool_import_certs_interactive "$@"
