#!/bin/bash

cd `dirname $0`/..
export WORKDIR=`pwd`

if [ -d `dirname $0`/../../imagebuilder-exp/systems ]; then
  # path to the cloned imagebuilder framework
  cd `dirname $0`/../../imagebuilder-exp
  export IMAGEBUILDER=`pwd`
else
  echo ""
  echo "please clone the experimental branch of"
  echo "https://github.com/hexdump0815/imagebuilder"
  echo "`dirname $0`/../../imagebuilder-exp"
  echo ""
  echo "giving up"
  echo ""
  exit 1
fi

cd ${WORKDIR}

. scripts/args-and-arch-check-functions.sh

export S_BUILD_ROOT=/compile/local/sonaremin-root
export DOWNLOAD_DIR=/compile/local/imagebuilder-download
export S_IMAGE_DIR=/compile/local/sonaremin-diskimage
export S_MOUNT_POINT=/tmp/sonaremin-mnt

# check that everything is there and set
if [ ! -f systems/${1}/mbr-partitions.txt ] && [ ! -f systems/${1}/gpt-partitions.txt ]; then
  echo ""
  echo "systems/${1}/mbr-partitions.txt or systems/${1}/gpt-partitions.txt does not exist - giving up"
  echo ""
  exit 1
fi
if [ ! -f systems/${1}/partition-mapping.txt ]; then
  echo ""
  echo "systems/${1}/partition-mapping.txt does not exist - giving up"
  echo ""
  exit 1
else
  # get partition mapping info
  . systems/${1}/partition-mapping.txt
  # check that all required variables are set
  if [ "$BOOTFS" != "" ]; then
    echo "BOOTFS=$BOOTFS"
  else
    echo ""
    echo "BOOTFS is not set in systems/${1}/partition-mapping.txt - giving up"
    echo ""
    exit
  fi
  if [ "$ROOTFS" != "" ]; then
    echo "ROOTFS=$ROOTFS"
  else
    echo ""
    echo "ROOTFS is not set in systems/${1}/partition-mapping.txt - giving up"
    echo ""
    exit
  fi
  # TODO: the btrfs code is in here for later experiments with it, but its not used
  #       for the sonaremin yet
  if [ "$ROOTFS" = "btrfs" ]; then
    if [ ! -x /bin/mkfs.btrfs ]; then
      echo ""
      echo "/bin/mkfs.btrfs is not available - please install the btrfs-progs package"
      echo ""
      exit 1
    fi
  fi
  if [ "$BOOTPART" != "" ]; then
    echo "BOOTPART=$BOOTPART"
  else
    echo ""
    echo "BOOTPART is not set in systems/${1}/partition-mapping.txt - giving up"
    echo ""
    exit
  fi
  if [ "$ROOTPART" != "" ]; then
    echo "ROOTPART=$ROOTPART"
  else
    echo ""
    echo "ROOTPART is not set in systems/${1}/partition-mapping.txt - giving up"
    echo ""
    exit
  fi
  if [ "$SWAPPART" != "" ]; then
    echo "SWAPPART=$SWAPPART"
  else
    echo ""
    echo "INFO: SWAPPART is not set in systems/${1}/partition-mapping.txt - this is ok"
    echo ""
  fi
fi

mkdir -p ${S_IMAGE_DIR}
mkdir -p ${S_MOUNT_POINT}

if [ -f ${S_IMAGE_DIR}/${1}-${2}.img ]; then
  echo ""
  echo "image file ${S_IMAGE_DIR}/${1}-${2}.img already exists - giving up for safety reasons ..."
  echo ""
  exit 1
fi

# we use less than the marketing capacity of the sd card as it is usually lower in reality: 7 of 8gb
truncate -s 0 ${S_IMAGE_DIR}/${1}-${2}.img
# the compressed btrfs root needs less space on disk
if [ "$ROOTFS" = "btrfs" ]; then
  fallocate -l 5G ${S_IMAGE_DIR}/${1}-${2}.img
else
  fallocate -l 7G ${S_IMAGE_DIR}/${1}-${2}.img
fi

losetup /dev/loop0 ${S_IMAGE_DIR}/${1}-${2}.img

if [ -f ${DOWNLOAD_DIR}/boot-${1}-${2}.dd ]; then
  dd if=${DOWNLOAD_DIR}/boot-${1}-${2}.dd of=/dev/loop0
fi

# inspired by https://github.com/jeromebrunet/libretech-image-builder/blob/libretech-cc-xenial-4.13/linux-image.sh
fdisk /dev/loop0 < ${WORKDIR}/files/mbr-partitions.txt

# this is to make sure we really use the new partition table and have all partitions around
partprobe /dev/loop0
losetup -d /dev/loop0
losetup --partscan /dev/loop0 ${S_IMAGE_DIR}/${1}-${2}.img

# get partition mapping info
. ${WORKDIR}/files/partition-mapping.txt
mkfs.vfat -F32 -n BOOTPART /dev/loop0p$BOOTPART
mkfs.vfat -F32 -n DATAPART /dev/loop0p$DATAPART
if [ "$ROOTFS" = "btrfs" ]; then
  mkfs -t btrfs -m single -L rootpart /dev/loop0p$ROOTPART
  mount -o ssd,compress-force=zstd,noatime,nodiratime /dev/loop0p$ROOTPART ${S_MOUNT_POINT}
else
  mkfs -t ext4 -O ^has_journal -m 2 -L rootpart /dev/loop0p$ROOTPART
  mount /dev/loop0p$ROOTPART ${S_MOUNT_POINT}
fi
mkdir ${MOUNT_POINT}/boot
mount /dev/loop0p$BOOTPART ${MOUNT_POINT}/boot
mkdir ${MOUNT_POINT}/data
mount /dev/loop0p$DATAPART ${MOUNT_POINT}/data

echo "copying over the root fs to the target image - this may take a while ..."
date
rsync -axADHSX --no-inc-recursive ${S_BUILD_ROOT}/ ${S_MOUNT_POINT}
date
echo "done"

# TODO: the non swappart code is in here for later experiments with it
#       but its not used for the sonaremin yet
if [ "$SWAPPART" != "" ]; then
  mkswap -L swappart /dev/loop0p$SWAPPART
else
  if [ "$ROOTFS" = "btrfs" ]; then
    btrfs subvolume create ${S_MOUNT_POINT}/swap
    chmod 755 ${S_MOUNT_POINT}/swap
    chattr -R +C ${S_MOUNT_POINT}/swap
    btrfs property set ${S_MOUNT_POINT}/swap compression none
  else
    mkdir ${S_MOUNT_POINT}/swap
  fi
  truncate -s 0 ${S_MOUNT_POINT}/swap/file.0
  if [ "$ROOTFS" = "btrfs" ]; then
    btrfs property set ${S_MOUNT_POINT}/swap/file.0 compression none
  fi
  fallocate -l 512M ${S_MOUNT_POINT}/swap/file.0
  chmod 600 ${S_MOUNT_POINT}/swap/file.0
  mkswap -L swapfile.0 ${S_MOUNT_POINT}/swap/file.0
fi

# create a customized fstab file
FSTAB_VFAT_BOOT="LABEL=BOOTPART /boot vfat defaults,uid=1000,gid=1000,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,showexec,utf8,flush 0 2"
FSTAB_VFAT_DATA="LABEL=DATAPART /boot vfat defaults,uid=1000,gid=1000,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,showexec,utf8,flush 0 2"
FSTAB_BTRFS_ROOT="LABEL=rootpart / btrfs defaults,ssd,compress-force=zstd,noatime,nodiratime 0 1"
FSTAB_EXT4_ROOT="LABEL=rootpart / ext4 defaults,noatime,nodiratime,errors=remount-ro 0 1"
FSTAB_SWAP_FILE="/swap/file.0 none swap sw 0 0"
FSTAB_SWAP_PART="LABEL=swappart none swap sw 0 0"

echo $FSTAB_VFAT_BOOT > ${S_MOUNT_POINT}/etc/fstab
echo $FSTAB_VFAT_DATA >> ${S_MOUNT_POINT}/etc/fstab
if [ "$ROOTFS" = "btrfs" ]; then
  echo $FSTAB_BTRFS_ROOT >> ${S_MOUNT_POINT}/etc/fstab
else
  echo $FSTAB_EXT4_ROOT >> ${S_MOUNT_POINT}/etc/fstab
fi
if [ "$SWAPPART" = "" ]; then
  echo $FSTAB_SWAP_FILE >> ${S_MOUNT_POINT}/etc/fstab
else
  echo $FSTAB_SWAP_PART >> ${S_MOUNT_POINT}/etc/fstab
fi

export KERNEL_VERSION=`ls ${S_BUILD_ROOT}/boot/*Image-* | sed 's,.*Image-,,g' | sort -u`
if [ "$PARTUUID_ROOT" = "YES" ]; then
  ROOT_PARTUUID=$(blkid | grep "/dev/loop0p$ROOTPART" | awk '{print $5}' | sed 's,",,g')
# TODO: should not be needed for the sonaremin
#   if [ -f ${S_MOUNT_POINT}/boot/extlinux/extlinux.conf ]; then
#     sed -i "s,ROOT_PARTUUID,$ROOT_PARTUUID,g" ${S_MOUNT_POINT}/boot/extlinux/extlinux.conf
#     sed -i "s,KERNEL_VERSION,$KERNEL_VERSION,g" ${S_MOUNT_POINT}/boot/extlinux/extlinux.conf
#   fi
  if [ -f ${S_MOUNT_POINT}/boot/menu/extlinux.conf ]; then
    sed -i "s,ROOT_PARTUUID,$ROOT_PARTUUID,g" ${S_MOUNT_POINT}/boot/menu/extlinux.conf
    sed -i "s,KERNEL_VERSION,$KERNEL_VERSION,g" ${S_MOUNT_POINT}/boot/menu/extlinux.conf
  fi
  if [ -f ${S_MOUNT_POINT}/boot/uEnv.ini ]; then
    sed -i "s,ROOT_PARTUUID,$ROOT_PARTUUID,g" ${S_MOUNT_POINT}/boot/uEnv.ini
    sed -i "s,KERNEL_VERSION,$KERNEL_VERSION,g" ${S_MOUNT_POINT}/boot/uEnv.ini
  fi
else
# TODO: should not be needed for the sonaremin
#   if [ -f ${S_MOUNT_POINT}/boot/extlinux/extlinux.conf ]; then
#     sed -i "s,ROOT_PARTUUID,LABEL=rootpart,g" ${S_MOUNT_POINT}/boot/extlinux/extlinux.conf
#     sed -i "s,KERNEL_VERSION,$KERNEL_VERSION,g" ${S_MOUNT_POINT}/boot/extlinux/extlinux.conf
#   fi
  if [ -f ${S_MOUNT_POINT}/boot/menu/extlinux.conf ]; then
    sed -i "s,ROOT_PARTUUID,LABEL=rootpart,g" ${S_MOUNT_POINT}/boot/menu/extlinux.conf
    sed -i "s,KERNEL_VERSION,$KERNEL_VERSION,g" ${S_MOUNT_POINT}/boot/menu/extlinux.conf
  fi
  if [ -f ${S_MOUNT_POINT}/boot/uEnv.ini ]; then
    sed -i "s,ROOT_PARTUUID,LABEL=rootpart,g" ${S_MOUNT_POINT}/boot/uEnv.ini
    sed -i "s,KERNEL_VERSION,$KERNEL_VERSION,g" ${S_MOUNT_POINT}/boot/uEnv.ini
  fi
fi

# for the amlogic m8x we will have to shorten the kernel and initrd filenames due to a 23 char limit
if [ "$1" = "amlogic_m8" ]; then
  ${S_MOUNT_POINT}/boot/shorten-filenames.sh
fi

df -h ${S_MOUNT_POINT} ${S_MOUNT_POINT}/boot
umount ${S_MOUNT_POINT}/data 
umount ${S_MOUNT_POINT}/boot 
umount ${S_MOUNT_POINT}

losetup -d /dev/loop0

rmdir ${S_MOUNT_POINT}

echo ""
echo "the image is now ready at ${S_IMAGE_DIR}/${1}-${2}.img"
echo ""
