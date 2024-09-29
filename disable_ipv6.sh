#!/bin/bash

# Disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf

# Apply sysctl changes
sysctl -p

# Disable IPv6 in network interfaces
sed -i 's/iface eth0 inet6 auto/#iface eth0 inet6 auto/' /etc/network/interfaces

# Restart networking
systemctl restart networking