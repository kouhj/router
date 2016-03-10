#!/bin/bash

#极1S固件结构（9008版以后）：
# 0x00000000 - 0x0003FFFF (0x010000): u-boot
# 0x00040000 - 0x0004FFFF (0x010000): boardinfo预留空间
# 0x00050000 - 0x001AFFFF (0x160000): kernel
# 0x001B0000 - 0x???????? (0x??????): squashfs

function print_help() {
echo -e "
$1: Extracts HiWiFi sysupgrade firmware images
Usage:  $1  <firmware.bin>  <target_dir>

"
}

#Extracts u-boot, kernel and rootfs from the sysupgrade image
# $1: Input sysupgrade image name
# $2: Empty output directory name
function extract_parts() {
	FW=$1
	
	# U-boot and boardinfo occupy fixed space 192K + 128K = 320K
	dd if=$FW of=$2/u-boot.bin bs=64k count=5 2>/dev/null
	
	# Kernel occupies from 0x50000 to the variable location where SQUASHFS MAGIC "hsqs" starts
	# So let's search where the SQUASHFS MAGIC "hsqs" is
	ROOTFS_START=$(xxd -u $FW | 
		grep '0000: 6873 7173' | # SQUASHFS MAGIC "hsqs"
		head -n 1 | awk -F: '{print strtonum("0x"$1)}')
	if [ "$ROOTFS_START" != "" ]; then
		echo "Found Squashfs Magic header at offset: $ROOTFS_START"
	else
		echo "Failed to find Squashfs Magic header in file."
		exit 1;
	fi

	# Calculate the size for kernel and extract it
	((KERNEL_BLOCKS=ROOTFS_START/64/1024-5))
	dd if=$FW of=$2/kernel.bin bs=64k skip=5 count=$KERNEL_BLOCKS 2>/dev/null

	# Extract the rest as rootfs
	((ROOTFS_SKIP_BLOCKS=ROOTFS_START/64/1024))
	dd if=$FW of=$2/rootfs.bin bs=64k skip=$ROOTFS_SKIP_BLOCKS 2>/dev/null
	# Reduce rootfs to the actual size, the end of which is marked by DEAD C0DE
	ROOTFS_SIZE=$(xxd -u $2/rootfs.bin |
		grep 'DEAD C0DE FFFF FFFF FFFF FFFF FFFF FFFF' |
		head -n 1 | awk -F: '{print strtonum("0x"$1)}')
	truncate -s $ROOTFS_SIZE $2/rootfs.bin 

}

# ========================= START =========================
if [ $# -ne 2 ]; then
	print_help $0
	exit 1
fi

BINDIR=`dirname $0`
IMG="${1}"
DIR="${2}"

# Check if the input image exists
if [ ! -f $IMG ]; then
	echo "Image file '$IMG' not found!"
	exit 1
fi

# Check if the output directory exists
if [ ! -d $DIR ]; then
	mkdir -p $DIR
else
	# Check if the directory is empty
	if test "$(ls -A "$DIR")"; then
		echo "Output direcotry '$DIR' is not empty. Cowardly rejecting to continue."
		#exit 1
	fi
fi

# Start to extract
extract_parts $IMG $DIR

# Try to unsquash the root file system
$BINDIR/unsquashfs4 -d ${DIR}/rootfs ${DIR}/rootfs.bin


