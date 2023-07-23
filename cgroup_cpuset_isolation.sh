#!/bin/bash

name="win10"
pid=/bin/ps -C qemu_system-x86_64
cpus="1,2,3,5,6,7"
ncpus=6
cgrouprootfs="/sys/fs/cgroup"
cgroupfs="${cgrouprootfs}/${name}"

# using separate CPUs for VM
# cgroup usage see https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html
# 'lscpu -e' to see which cpus to use
echo "+cpuset" > ${cgrouprootfs}/cgroup.subtree_control
mkdir -p ${cgroupfs}
echo ${cpus} > ${cgroupfs}/cpuset.cpus
echo "root" > ${cgroupfs}/cpuset.cpus.partition
echo "${pid}" > ${cgroupfs}/cgroup.procs

# setting performance governor for QEMU CPUs
#for i in `seq 8 15` ; do
#  echo performance >/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor
#done



