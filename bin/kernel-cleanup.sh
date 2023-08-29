#!/bin/bash

# List all installed kernel versions
kernels=$(ls /boot | grep -E '(vmlinuz|initrd|System.map)-[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-generic' | sed -r 's/.*-([0-9]+\.[0-9]+\.[0-9]+-[0-9]+)-generic/\1/' | sort -V)

# Keep only the latest kernel version
kernels_to_remove=$(echo "$kernels" | head -n -1)

# Remove old kernel versions
for kernel in $kernels_to_remove; do
    #echo "Removing kernel version $kernel"
    #echo sudo rm -f /boot/*-$kernel-generic
    du -hs /boot/*-$kernel-generic
done

