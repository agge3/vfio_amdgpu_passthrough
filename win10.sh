#!/usr/bin/env bash

# variable assignment
CORES=2
THREADS=2
SOCKETS=1
RAM=16384
GPU=03:00.0
GPU_AUDIO=03:00.1

#name=win10
#pid="${$}"
#cpus="1,2,3,5,6,7"
#ncpus=6
#cgrouprootfs="/sys/fs/cgroup"
#cgroupfs="${cgrouprootfs}/${name}"

#echo "PID: ${pid}"

# using separate CPUs for VM
# cgroup usage see https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html
# 'lscpu -e' to see which cpus to use
#echo "+cpuset" > ${cgrouprootfs}/cgroup.subtree_control
#mkdir -p ${cgroupfs}
#echo ${cpus} > ${cgroupfs}/cpuset.cpus
#echo "root" > ${cgroupfs}/cpuset.cpus.partition
#echo "${pid}" > ${cgroupfs}/cgroup.procs

# setting performance governor for QEMU CPUs
#for i in `seq 0 7` ; do
#  echo performance >/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor
#done

# allocate hugepages
#mkdir /dev/hugepages
#mount /dev/hugepages
#sysctl vm.nr_hugepages=8192

setCPUGovernor() {
	cpuCount=0
	for core in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
		echo $1 > $core
		echo "CPU $cpuCount governor: $1"
		cpuCount=$((cpuCount+1))
	done
}

setCPUGovernor performance

sysctl kernel.sched_rt_runtime_us=-1

./cpuset -e -c 0,1,4,5 -m 0

# nice -n -5 \
qemu-system-x86_64 \
    -name "win10" \
    -enable-kvm \
    -machine type=q35,accel=kvm,kernel_irqchip=on,vmport=off \
    -drive file=/usr/share/edk2-ovmf/OVMF_CODE.fd,readonly=on,format=raw,if=pflash \
    -drive file=/usr/share/edk2-ovmf/OVMF_VARS.fd,format=raw,if=pflash \
    -boot c \
    -cpu host,topoext,tsc_deadline,tsc_adjust,kvm=off,hv_vendor_id=amdgpu,hv_relaxed,hv_vpindex,hv_runtime,hv_synic,hv_stimer,hv_reset,hv_frequencies,hv_tlbflush,hv_reenlightenment,hv_time,-aes,hv_vapic,hv_spinlocks=0x1fff,hv_ipi,-kvm,l3-cache \
    -smp $((CORES*THREADS)),sockets=$SOCKETS,cores=$CORES,threads=$THREADS \
    -m $RAM \
    -mem-path /dev/hugepages \
    -overcommit mem-lock=off,cpu-pm=on \
    -rtc clock=host,base=localtime,driftfix=slew \
    -global kvm-pit.lost_tick_policy=delay \
    -machine hpet=off \
    -msg timestamp=on \
    -cdrom /home/agge/iso/virtio-win-0.1.229.iso \
    -drive file=$HOME/vm/win10.img,id=hdd,format=raw,if=virtio,discard=unmap \
    -device virtio-net,netdev=vmnic -netdev user,id=vmnic \
    -device pcie-root-port,chassis=1,bus=pcie.0,id=root.1 \
    -device vfio-pci,host=$GPU,bus=root.1,addr=00.0,multifunction=on \
    -device vfio-pci,host=$GPU_AUDIO,bus=root.1,addr=00.1 \
    -vga none \
    -nographic \
    -parallel none \
    -nographic \
    -nodefaults \
    -no-user-config \
    -usb \
    -device usb-host,hostbus=1,hostport=7 \
    -device usb-host,hostbus=1,hostport=8 \
    -device usb-host,hostbus=1,hostport=9 \
    -device usb-host,hostbus=1,hostport=10 \
    $@ \
    && PID = $(pgrep qemu) \
    && chrt -f -p 99 $PID
# scheduler chrt, -f fifo, -p prio, 99 highest, $PID qemu pid

#wait $pid

#setCPUGovernor schedutil

#./cpuset -d

#./cpupin /home/agge/vm/win10.img 6 0

# deallocating hugepages
#sysctl vm.nr_hugepages=0
#unmount /dev/hugepages

# removing cgroup cpuset
#echo "${pid}" > ${cgrouprootfs}/cgroup.procs
#rm -r ${cgroupfs}

# setting schedutil governor for qemu cpus
#for i in `seq 0 7` ; do
#  echo schedutil >/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor
#done
