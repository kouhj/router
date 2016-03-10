#!/bin/bash
BINDIR=`dirname $0`

IMG="${2}"
DIR="${1}"

function print_help() {
echo -e "
$1: Builds HiWiFi sysupgrade firmware images
Usage:  $1  <extracted_dir> <target_firmware.bin>

"
}

if [ $# -ne 2 ]; then
	print_help $0
	exit 0
fi


rm -f $DIR/rootfs-new.bin $IMG
$BINDIR/mksquashfs4 $DIR/rootfs $DIR/rootfs-new.bin -all-root -comp xz -Xpreset 9 -Xe -Xlc 0 -Xlp 2 -Xpb 2 -b 256k
#cp -af $DIR/rootfs.bin $DIR/rootfs-new.bin
$BINDIR/pad_image squashfs $DIR/rootfs-new.bin

cat $DIR/{u-boot.bin,kernel.bin,rootfs-new.bin} > $IMG




