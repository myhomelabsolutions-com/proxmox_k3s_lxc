#!/bin/bash

# Load required kernel modules
modules=(
    "overlay"
    "nf_nat"
    "xt_conntrack"
    "br_netfilter"
)

for module in "${modules[@]}"; do
    if ! lsmod | grep -q "$module"; then
        modprobe "$module"
    fi
done

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Create /dev/kmsg if it doesn't exist
if [ ! -e /dev/kmsg ]; then
    mknod /dev/kmsg c 1 11
fi

exit 0