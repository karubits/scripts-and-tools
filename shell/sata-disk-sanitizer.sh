#!/bin/bash

# Author: Karubits
# Date Created: 31/8/2022
# Description:
# A script for securely erase SATA disk drives, update firmeware, run a health check, and generating a report.
#
# How to use:
#	To erase multiple disks
#	./sata-disk-sanitizer.sh sda sdb
#
#	To erase a single disk:
#	./sata_wipe.sh sda
#
# â  CAUTION â  This is a desturctive process. Ensure you have enter the correct disk.


# ð  A few prequisties based on using a live Ubuntu distribution
echo "Installing prerequisites..."
fwupdmgr get-updates -y
sudo apt update
sudo apt install smartmontools hdparm -y
echo "Updating smartmontools database..."
update-smart-drivedb
clear

for DISK in "$@"
do
	[[ -z "$DISK" ]] && exit 0 || echo "Not NULL"
	echo " "
	echo "------------------------------"
	echo "â¢ Targeting $DISK for desctruction..."
	echo "â¢ $(lsblk /dev/$DISK -o model,serial | tail -n +2 | sed 's/^[ \t]*//;s/[ \t]*$//') $(hdparm -I /dev/$DISK | grep Firmware | sed 's/^[ \t]*//;s/[ \t]*$//')"
	echo "------------------------------"
	echo " "
	# Check to see if the disk is frozen
	if [[ $(hdparm -I /dev/$DISK | grep "not	frozen") ]];
		then
			echo "â Disk is not frozen. Continuing..."
			echo "------------------------------"
			echo " "

			echo "ð¹ Now formatting $DISK with sfdisk..."
			sudo sfdisk --force --color=always --delete /dev/$DISK

			echo "ð¹Now performing secure erase..."

			# The spec requires setting a password before been able to use secure-erase. The password is cleared with the next command.
			sudo hdparm --user-master u --security-set-pass password /dev/$DISK
			sudo hdparm --user-master u --security-erase-enhanced password /dev/$DISK
			echo "------------------------------"
		else
			echo "ð ERROR: Disk is still frozen, put the PC to sleep ð¤ and wake it up again"
			exit 0
	fi

	echo ""
	echo "ð¹ Creating msdos partition label..."
	parted -s /dev/$DISK mklabel msdos
	echo "------------------------------"
	echo " "

	echo "ð¹ Updating firmware....(if applicable)"
	fwupdmgr update -y --no-reboot-check
	echo "------------------------------"
	echo " "

	# Smart Test (Short)
	echo "ð¹ Now running a short smart test to confirm the disks health..."
	smartctl -t short /dev/sda
	sleep 2m
	echo " "
	echo "â´ RESULT: $(smartctl -H /dev/sda | grep overall-health)"
	echo "------------------------------"
	echo " "

	# REPORT GENERATION
	DISK_FILE=$(lsblk /dev/$DISK -o model,serial | tail -n +2 | awk '{$1=$1};1' | sed 's/ /_/g' ).txt
	echo "ð¹ Writting report to $DISK_FILE..."
	touch $DISK_FILE
	echo "DISK REPORT:" > $DISK_FILE
	echo " " >> $DISK_FILE
	date >> $DISK_FILE
	echo " " >> $DISK_FILE
	hdparm -I /dev/sda | grep -A3 "Model Number:" |  sed 's/^[ \t]*//;s/[ \t]*$//' >> $DISK_FILE
	echo " " >> $DISK_FILE
        echo "##################################" >> $DISK_FILE
        echo "SSD DISK HEALTH REPORT" >> $DISK_FILE
        echo "##################################" >> $DISK_FILE
	smartctl -H /dev/sda | grep overall-health >> $DISK_FILE
        echo " " >> $DISK_FILE
	smartctl -A /dev/sda | grep -A99 "SMART Attributes Data Structure" >> $DISK_FILE
	echo " " >> $DISK_FILE
	smartctl -a /dev/$DISK | grep -A23 "SMART Self-test log" >> $DISK_FILE
	echo " "
	echo "ð $DISK Done"
done
