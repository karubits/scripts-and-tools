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
echo ""

for DISK in "$@"
do

    echo ""
    echo "☢ This process will destory all data on:"
    echo "------------------------------"
    sudo nvme list /dev/$DISK
    echo "------------------------------"
    echo ""
    echo "🔹 Now erasing $DISK..."
    sudo nvme format -s1 /dev/$DISK --force
    echo "------------------------------"
    echo ""

    echo "🔹 Creating msdos partition label..."
    sudo parted -s /dev/$DISK mklabel msdos

    echo "🔹 Updating firmware..."
    sudo fwupdmgr update -y --no-reboot-check
    echo ""

    # REPORT GENERATION:
    DISK=$(lsblk /dev/$DISK -o model,serial | tail -n +2)
    DISK_FILE=${DISK// /_}
    touch $DISK_FILE.txt
    sudo nvme list /dev/$DISK > $DISK_FILE.txt
    echo " " >> $DISK_FILE.txt
    echo "##################################" >> $DISK_FILE.txt
    echo "SSD DISK HEALTH REPORT" >> $DISK_FILE.txt
    echo "##################################" >> $DISK_FILE.txt
    sudo nvme smart-log /dev/$DISK >> $DISK_FILE.txt
    echo ""
    echo "🏁 $DISK Done"

done
