#!/bin/bash
du -hs /boot/*-generic
echo 'sudo rm -v /boot/{vmlinuz,System.map,initrd.img,config}-{5.15.0-82,5.19.0-46,5.19.0-50}-generic'
echo 'cp /boot/initrd.img-6.2.0-31-generic ~ecc/tmp'
echo 'rm /boot/initrd.img-6.2.0-31-generic'
exit

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
