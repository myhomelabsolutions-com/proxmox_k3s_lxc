#!/bin/sh -e

echo 'overlay' >> /etc/modules
mount --make-rshared /

echo "lxc.apparmor.profile=unconfined" >> /etc/lxc/default.conf
echo "lxc.cgroup.devices.allow=a" >> /etc/lxc/default.conf
echo "lxc.cap.drop=" >> /etc/lxc/default.conf
echo "lxc.mount.auto=proc:rw sys:rw" >> /etc/lxc/default.conf
echo "lxc.selinux.context=" >> /etc/lxc/default.conf
echo "lxc.seccomp.profile=" >> /etc/lxc/default.conf
echo "lxc.cgroup.memory.use_hierarchy=1" >> /etc/lxc/default.conf