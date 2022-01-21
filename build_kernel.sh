#!/bin/bash
set -x

. ./build_env.sh

echo "kerneldir = $KERNELDIR"
echo "ramfs_source = $RAMFS_SOURCE"

RAMFS_TMP="/tmp/arter97-op9-ramdisk"

echo "ramfs_tmp = $RAMFS_TMP"
cd $KERNELDIR

if [[ "${1}" == "skip" ]] ; then
	echo "Skipping Compilation"
else
	echo "Compiling kernel"
#	cp defconfig .config
	local CONF
	local args=()
	for i ;do
		[[ $i =~ ^([gnx]|menu)config$ ]] && CONF=$1 || args+=($i)
		shift
	done
	set ${args[@]}

	remake ARCH=arm64 CROSS_COMPILE_ARM32=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu CROSS_COMPILE=aarch64-elf- LLVM=1 O=out -j4 arter97-cust_defconfig
	[[ -n $CONF ]] && remake ARCH=arm64 CROSS_COMPILE_ARM32=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu CROSS_COMPILE=aarch64-elf- LLVM=1 O=out -j4 $CONF
	remake ARCH=arm64 CROSS_COMPILE_ARM32=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu CROSS_COMPILE=aarch64-elf- LLVM=1 O=out -j4  || exit 1
fi

echo "Building new ramdisk"
#remove previous ramfs files
rm -rf '$RAMFS_TMP'*
rm -rf $RAMFS_TMP
rm -rf $RAMFS_TMP.cpio
#copy ramfs files to tmp directory
cp -axpP $RAMFS_SOURCE $RAMFS_TMP
cd $RAMFS_TMP

#clear git repositories in ramfs
find . -name .git -exec rm -rf {} \;
find . -name EMPTY_DIRECTORY -exec rm -rf {} \;

$KERNELDIR/ramdisk_fix_permissions.sh 2>/dev/null

cd $KERNELDIR
rm -rf $RAMFS_TMP/tmp/*

cd $RAMFS_TMP
find . | fakeroot cpio -H newc -o | pigz > $RAMFS_TMP.cpio.gz
ls -lh $RAMFS_TMP.cpio.gz
cd $KERNELDIR

echo "Making new boot image"
mkbootimg \
    --kernel $KERNELDIR/out/arch/arm64/boot/Image.gz \
    --ramdisk $RAMFS_TMP.cpio.gz \
    --pagesize 4096 \
    --os_version     $OS \
    --os_patch_level $SPL \
    --header_version 3 \
    -o $KERNELDIR/out/boot.img

GENERATED_SIZE=$(stat -c %s $KERNELDIR/out/boot.img)
if [[ $GENERATED_SIZE -gt $PARTITION_SIZE ]]; then
	echo "boot.img size larger than partition size!" 1>&2
	exit 1
fi

echo "done"
ls -al $KERNELDIR/out/boot.img
echo ""
