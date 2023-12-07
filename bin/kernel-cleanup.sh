#!/bin/bash

du -hs /boot/*-generic
echo
echo "df -h | grep -E '^Filesystem|boot$'"
df -h | grep -E '^Filesystem|boot$'


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

dpkg --list:
EOF

dpkg --list | grep -Ei '(linux-image|linux-headers)-[0-9]+' | awk '/^ii/{print $2}' | grep -v $(uname -r)

mkdir -p ~ecc/tmp/current-kernel
echo
echo sudo cp -v /boot/*$current_kernel* ~ecc/tmp/current-kernel
echo

# Calculate the limit for the iteration
((counter = $(echo "$older_kernels" | grep -c .) - 1))
# Remove old kernel versions but 1, and also keep the current one.
echo "$older_kernels" | while read -r kernel; do
  #printf "\n# Removing kernel version %s\n" "$kernel"
  #du -hs /boot/*-$kernel-generic
  test "$kernel" || { echo skip ; continue ;}
  echo "sudo apt-get --purge remove linux-image-$kernel-generic linux-headers-$kernel-generic"
  echo "sudo rm -fv /boot/*-$kernel-generic"
  ((--counter)) || break
done
