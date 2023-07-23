#!/bin/bash

# source kvm.conf
source /etc/libvirt/hooks/kvm.conf

# removing cgroup cpuset
echo "${pid}" > ${cgrouprootfs}/cgroup.procs
rmdir ${cgroupfs}
