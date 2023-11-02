#!/bin/bash

du -hs /boot/*-generic

# List all installed kernel versions
current_kernel="$(uname -r)"
all_kernels=$(
  du -hs /boot/*-generic | xargs -I {} basename {} | \
  grep -Eo '[0-9]+[0-9.]+-[0-9]+' | sort | uniq | sort -V
)
older_kernels=$(
  echo "$all_kernels" | \
  grep -v "${current_kernel%-*}"
)
cat <<EOF

Kernels:
$older_kernels
$current_kernel *** current kernel ***

EOF

mkdir -p /var/tmp/current-kernel
echo cp -v /boot/*$current_kernel* /var/tmp/current-kernel

# Calculate the limit for the iteration
((counter = $(echo "$older_kernels" | grep -c .) - 1))
# Remove old kernel versions but 1, and also keep the current one.
echo "$older_kernels" | while read -r kernel; do
  #printf "\n# Removing kernel version %s\n" "$kernel"
  #du -hs /boot/*-$kernel-generic
  test "$kernel" || { echo skip ; continue ;}
  echo "sudo rm -f /boot/*-$kernel-generic"
  ((--counter)) || break
done

exit
