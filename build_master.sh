#!/bin/bash
set -x
. ./build_env.sh

if [[ "${1}" != "skip" ]] ; then
#	git clean -fdx
	$KERNELDIR/build_kernel.sh "$@" || exit 1
fi

if [ -e $KERNELDIR/out/boot.img ] ; then
	rm $KERNELDIR/out/arter97-kernel-$VERSION.zip 2>/dev/null
	cp $KERNELDIR/out/boot.img ./out/arter97-kernel-$VERSION.img

	# Pack AnyKernel3
	rm -rf $KERNELDIR/out/kernelzip
	mkdir $KERNELDIR/out/kernelzip
	echo "
kernel.string=arter97 kernel $(cat version) @ xda-developers
do.devicecheck=0
do.modules=0
do.cleanup=1
do.cleanuponabort=0
block=/dev/block/bootdevice/by-name/boot
is_slot_device=1
ramdisk_compression=gzip
" > $KERNELDIR/out/kernelzip/props
	cp -rp ~/android/anykernel/* $KERNELDIR/out/kernelzip/
	find $KERNELDIR/out -name '*.dtb' -exec cat {} + > $KERNELDIR/out/kernelzip/dtb
	cp $KERNELDIR/out/arch/arm64/boot/dtbo.img $KERNELDIR/out/kernelzip/
	touch $KERNELDIR/out/kernelzip/vendor_boot
	cd $KERNELDIR/out/kernelzip/
	7z a -mx9 arter97-kernel-$VERSION-tmp.zip *
	7z a -mx0 arter97-kernel-$VERSION-tmp.zip ../arch/arm64/boot/Image.gz
	zipalign -v 4 arter97-kernel-$VERSION-tmp.zip ../arter97-kernel-$VERSION.zip
	rm arter97-kernel-$VERSION-tmp.zip
	cd ..
	ls -al arter97-kernel-$VERSION.zip
fi
