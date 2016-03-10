#!/bin/bash
BASEDIR=`dirname $0`

function print_help() {
echo -e "$1: Modify a HiWiFi sysupgrade firmware images to support SSH and console
Usage:  $1  <version_number>
Example: $1  9016

Notes: 1. Input firmware is searched in the 'original' folder
       2. Modified firmware will be save to folder 'rooted' 
"
}

if [ $# -ne 1 ]; then
	print_help $0
	exit 0
fi

VER=${1}

# Check if it is a 4-digit version number
if [[ "$VER" =~ 9[0-9][0-9][0-9] ]] ; then
	echo Processing version $VER ...
else
	echo Invalid version $VER.
	exit 1
fi

IMG=$(ls $BASEDIR/original/0.${VER}* 2>/dev/null)
if [ -z "$IMG" ]; then
	echo "No image found for version $VER."
	exit 1
fi

DIR=working/$VER
IMGNEW=rooted/$(basename $IMG)
ROOTFS_BASE=$DIR/rootfs
rm -rf $DIR
$BASEDIR/../scripts/extract-hiwifi-firmware.sh  $IMG  $DIR


if [ $? -eq 0 ]; then
	# Enable Console Access. Add board name "HC5661" to lib/ralink.sh
	echo 'Trying to enable Console Port shell access ...'
	sed -i 's_"\(BL-T8100" | "HC5641"\))_\1 | "HC5661")_' $ROOTFS_BASE/lib/ralink.sh              #9016
	sed -i 's#console_enable=0#console_enable=1#' $ROOTFS_BASE/lib/functions/system.sh            #9015
	sed -i 's_^\([ \t]*\)\(sed.*login.*inittab.*\)$_\1# \2_' $ROOTFS_BASE/lib/functions/system.sh #9013
	# Enable SSH Access
	echo 'Trying to enable SSH access ...'
	ln -sf ../init.d/dropbear  $ROOTFS_BASE/etc/rc.d/S39dropbear
fi

$BASEDIR/../scripts/build-hiwifi-firmware.sh  $DIR  $IMGNEW
# Replace u-boot from version 9003
echo 'Replace bootloader with version 9003 ...'
dd if=$BASEDIR/original/9003-u-boot.bin of=$IMGNEW conv=notrunc 2>/dev/null

echo 'All Done. Enjoy!'
echo

