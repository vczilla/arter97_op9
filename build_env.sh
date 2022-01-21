export KERNELDIR=`readlink -f .`
export RAMFS_SOURCE=`readlink -f $KERNELDIR/ramdisk`
export PARTITION_SIZE=134217728

export OS="11.0.0"
export SPL="2021-11"
export VERSION="$(cat $KERNELDIR/version)-$(date +%F | sed s@-@@g)"
echo version: $VERSION
