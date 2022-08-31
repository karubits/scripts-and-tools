#!/bin/bash

# Author: Karubits
# Date Created: 31/8/2022
# Description:
# A script for securely erasing NVME disks and generate a report including serial number, firmware, and disk health. 
# 
# How to use: 
#	To erase multiple disks
#	./nvme_wipe.sh nvme0n1
#
#	To erase a single disk:
#	./nvme_wipe.sh nvme0n1
#
# ⚠ CAUTION ⚠ This is a desturctive process. Ensure you have enter the correct disk. 


# 💠 A few prequisties based on using a live Ubuntu distribution
sudo apt update
sudo apt install nvme-cli -y
clear
echo "🔹 Updating firmware..."
sudo fwupdmgr update -y --no-reboot-check
echo " "

echo "------------------------------"
echo "Note:"
echo "If you see this below error, suspend and wake up the PC:"
echo "Example Error - NVMe status: INVALID_FORMAT: The LBA Format specified is not supported. This may be due to various conditions(0x410a)"
echo "------------------------------"

echo " "

for DISK in "$@"
do

    echo " "
    echo "☢ This process will destory all data on:"
    echo "------------------------------"
    sudo nvme list | grep $DISK
    echo "------------------------------"
    echo " "
    echo "🔹 Now erasing $DISK..."
    sudo nvme format -s1 /dev/$DISK --force
    sudo nvme format /dev/$DISK --force
    echo " "
    echo "🔹 Creating msdos partition label..."
    sudo parted -s /dev/$DISK mklabel msdos

    # REPORT GENERATION:
    echo "🔹 Genearting disk report..."
    DISK_MS=$(lsblk /dev/$DISK -o model,serial | tail -n +2)
    DISK_FILE=${DISK_MS// /_}.txt
    touch $DISK_FILE
    echo "NVME Disk Report:" > $DISK_FILE
    echo " " >> $DISK_FILE
    date >> $DISK_FILE
    echo " " >> $DISK_FILE
    echo $DISK_MS >> $DISK_FILE 
    echo " " >> $DISK_FILE
    sudo nvme list | grep Node >> $DISK_FILE
    sudo nvme list | grep $DISK >> $DISK_FILE
    echo " " >> $DISK_FILE
    echo "##################################" >> $DISK_FILE
    echo "SSD DISK HEALTH REPORT" >> $DISK_FILE
    echo "##################################" >> $DISK_FILE
    sudo nvme smart-log /dev/$DISK >> $DISK_FILE
    echo ""
    echo "🏁 $DISK Done"

done
