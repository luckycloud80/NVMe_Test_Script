#!/bin/bash

SSD=/dev/nvme0n1

# Do Secure Erase into NVMe SSD
nvme format -s 1 "${SSD}"
#echo "Secure Erase done\n"

# Do set LBA into NVMe SSD
nvme format -l 0 "${SSD}"
#echo "Set LBA\n"

i=0
while [ $i -lt 5 ]; do

# Creat a partition into NVMe SSD
	(
	echo g # Create a new GPT disklabel
	sleep 0.1
	echo n # add a new partition
	sleep 0.1
#	echo p # Select Primary
	echo 1 # partition number
	sleep 0.1
	echo 2048 # First sector : default 2048
	sleep 0.1
	echo # Last sector
	sleep 0.1
	echo i # Selected partition information
	sleep 0.1
	echo w # save
	) | fdisk "${SSD}"
sleep 1

# make ext4 file system into SSD
	(	
	echo y 
	) | mkfs -t ext4 "${SSD}"p1
sleep 1

# wipe ext4 file system signature from SSD
wipefs -a -f "${SSD}"p1
sleep 1
#wipefs -a -f "${SSD}"
#sleep 1

# delete ext4 file system from SSD
	(	
	echo d
	sleep 0.1
	echo i
	sleep 0.1
	echo w
	) | fdisk "${SSD}"

	echo ""
	echo "$i"
	echo ""
	i=$(($i+1))

done

echo "completed making filesystem "${i}" times"
                                                         1,1           Top
