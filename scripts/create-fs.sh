#!/bin/bash

cd `dirname $0`/..
export WORKDIR=`pwd`

export S_BUILD_ROOT=/compile/local/sonaremin-root
export S_DOWNLOAD_DIR=/compile/local/sonaremin-download

if [ -d ${S_BUILD_ROOT} ]; then
  echo ""
  echo "S_BUILD_ROOT ${S_BUILD_ROOT} already exists - giving up for safety reasons ..."
  echo ""
#  exit 1
fi

if [ ! -d ${S_DOWNLOAD_DIR} ]; then
  echo ""
  echo "download dir ${S_DOWNLOAD_DIR} does not exists - please run get-files.sh first ..."
  echo ""
  exit 1
fi

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

export DOWNLOAD_DIR=/compile/local/imagebuilder-download

if [ ! -d ${DOWNLOAD_DIR} ]; then
  echo ""
  echo "download dir ${DOWNLOAD_DIR} does not exists - please run ${IMAGEBUILDER}/scripts/get-files.sh first ..."
  echo ""
  exit 1
fi

if [ "${1}" != $(cat ${DOWNLOAD_DIR}/system.txt)" ] || \
   [ "${2}" != $(cat ${DOWNLOAD_DIR}/arch.txt)" ] || \
   [ "focal" != "$(cat ${DOWNLOAD_DIR}/release.txt)" ]; then
  echo ""
  echo "system and arch given on the cmdline (${1} ${2}) plus release=focal"
  echo "do not match the ones of the download folder ${DOWNLOAD_DIR}"
  echo "($(cat ${DOWNLOAD_DIR}/system.txt) $(cat ${DOWNLOAD_DIR}/arch.txt) $(cat ${DOWNLOAD_DIR}/release.txt)) - please fix the download dir first - giving up"
  echo ""
  exit 1
fi

export S_BUILD_ROOT_CACHE=/compile/local/imagebuilder-${2}-sonaremin-cache

if [ ! -d ${S_BUILD_ROOT_CACHE} ]; then
  ${IMAGEBUILDER}/scripts/create-fs-cache.sh ${2} sonaremin
else
  echo ""
  echo "root fs cache for ${2} sonaremin exists, so using it"
  echo ""
fi

echo ""
echo "copying over the root cache to the target root - this may take a while ..."
date
rsync -axADHSX --no-inc-recursive ${S_BUILD_ROOT_CACHE}/ ${S_BUILD_ROOT}
date
echo "done"
echo ""

cp ${WORKDIR}/scripts/create-chroot-02.sh ${S_BUILD_ROOT}

mount -o bind /dev ${S_BUILD_ROOT}/dev
mount -o bind /dev/pts ${S_BUILD_ROOT}/dev/pts
mount -t sysfs /sys ${S_BUILD_ROOT}/sys
mount -t proc /proc ${S_BUILD_ROOT}/proc
# TODO: this can most probably go
#cp /proc/mounts ${S_BUILD_ROOT}/etc/mtab  
#cp /etc/resolv.conf ${S_BUILD_ROOT}/etc/resolv.conf 

chroot ${S_BUILD_ROOT} /create-chroot-02.sh

cd ${S_BUILD_ROOT}/

rm -f create-chroot-stage-0?.sh

tar --numeric-owner -xhzf ${IMAGEBUILDER}/downloads/kernel-${1}-${2}.tar.gz

if [ -d ${IMAGEBUILDER}/boot-extra-${1} ]; then
  mkdir -p boot/extra
  cp -r ${IMAGEBUILDER}/boot-extra-${1}/* boot/extra
fi

# the sonaremin uses syslinux with /boot/menu as dir - so remove /boot/extlinux and add /boot/menu per system
rm -rf boot/extlinux

if [ -d ${IMAGEBUILDER}/files/extra-files ]; then
  ( cd ${IMAGEBUILDER}/files/extra-files ; tar cf - . ) | tar xhf -
fi
if [ -d ${IMAGEBUILDER}/files/extra-files-${2} ]; then
  ( cd ${IMAGEBUILDER}/files/extra-files-${2} ; tar cf - . ) | tar xhf -
fi
if [ -d ${IMAGEBUILDER}/files/extra-files-focal ]; then
  ( cd ${IMAGEBUILDER}/files/extra-files-focal ; tar cf - . ) | tar xhf -
fi
if [ -d ${IMAGEBUILDER}/files/extra-files-${2}-focal ]; then
  ( cd ${IMAGEBUILDER}/files/extra-files-${2}-focal ; tar cf - . ) | tar xhf -
fi
if [ -d ${IMAGEBUILDER}/systems/${1}/extra-files ]; then
  ( cd ${IMAGEBUILDER}/systems/${1}/extra-files ; tar cf - . ) | tar xhf -
fi
if [ -d ${IMAGEBUILDER}/systems/${1}/extra-files-${2} ]; then
  ( cd ${IMAGEBUILDER}/systems/${1}/extra-files-${2} ; tar cf - . ) | tar xhf -
fi
if [ -d ${IMAGEBUILDER}/systems/${1}/extra-files-focal ]; then
  ( cd ${IMAGEBUILDER}/systems/${1}/extra-files-focal ; tar cf - . ) | tar xhf -
fi
if [ -d ${IMAGEBUILDER}/systems/${1}/extra-files-${2}-focal ]; then
  ( cd ${IMAGEBUILDER}/systems/${1}/extra-files-${2}-focal ; tar cf - . ) | tar xhf -
fi

tar --numeric-owner -xzf ${S_DOWNLOAD_DIR}/files/xrdp-focal-${2}.tar.gz
# unpack this before the extra-files as they bring an adapted config
tar --numeric-owner -xzf ${S_DOWNLOAD_DIR}/files/xorgxrdp-focal-${2}.tar.gz
tar --numeric-owner -xzf ${S_DOWNLOAD_DIR}/files/raveloxmidi-focal-${2}.tar.gz

if [ -d ${WORKDIR}/files/extra-files ]; then
  ( cd ${WORKDIR}/files/extra-files ; tar cf - . ) | tar xhf -
fi
if [ -d ${WORKDIR}/files/extra-files-${2} ]; then
  ( cd ${WORKDIR}/files/extra-files-${2} ; tar cf - . ) | tar xhf -
fi
if [ -d ${WORKDIR}/systems/${1}/extra-files ]; then
  ( cd ${WORKDIR}/systems/${1}/extra-files ; tar cf - . ) | tar xhf -
fi
if [ -d ${WORKDIR}/systems/${1}/extra-files-${2} ]; then
  ( cd ${WORKDIR}/systems/${1}/extra-files-${2} ; tar cf - . ) | tar xhf -
fi

# TODO: not sure if this is all needed for the sonaremin
# if [ -f ${IMAGEBUILDER}/systems/${1}/rc-local-additions.txt ]; then
#   echo "" >> etc/rc.local
#   echo "# additions for ${1}" >> etc/rc.local
#   echo "" >> etc/rc.local
#   cat ${IMAGEBUILDER}/systems/${1}/rc-local-additions.txt >> etc/rc.local
# fi
# if [ -f ${IMAGEBUILDER}/systems/${1}/rc-local-additions-focal.txt ]; then
#   echo "" >> etc/rc.local
#   echo "# additions for ${1} focal" >> etc/rc.local
#   echo "" >> etc/rc.local
#   cat ${IMAGEBUILDER}/systems/${1}/rc-local-additions-focal.txt >> etc/rc.local
# fi
if [ -f ${WORKDIR}/systems/${1}/rc-local-additions.txt ]; then
  echo "" >> etc/rc.local
  echo "# additions for ${1}" >> etc/rc.local
  echo "" >> etc/rc.local
  cat ${WORKDIR}/systems/${1}/rc-local-additions.txt >> etc/rc.local
fi
echo "" >> etc/rc.local
echo "exit 0" >> etc/rc.local

# TODO: not sure if this is all needed for the sonaremin
# # adjust some config files if they exist
# if [ -f etc/modules-load.d/cups-filters.conf ]; then
#   sed -i 's,^lp,#lp,g' etc/modules-load.d/cups-filters.conf
#   sed -i 's,^ppdev,#ppdev,g' etc/modules-load.d/cups-filters.conf
#   sed -i 's,^parport_pc,#parport_pc,g' etc/modules-load.d/cups-filters.conf
# fi
# if [ -f etc/NetworkManager/NetworkManager.conf ]; then
#   sed -i 's,^managed=false,managed=true,g' etc/NetworkManager/NetworkManager.conf
#   touch etc/NetworkManager/conf.d/10-globally-managed-devices.conf
# fi
# if [ -f etc/default/numlockx ]; then
#   sed -i 's,^NUMLOCK=auto,NUMLOCK=off,g' etc/default/numlockx
# fi
# if [ -f etc/default/apport ]; then
#   sed -i 's,^enabled=1,enabled=0,g' etc/default/apport
# fi

# remove the generated ssh keys so that fresh ones are generated on
# first boot for each installed image
rm -f etc/ssh/*key*
# activate the one shot service to recreate them on first boot
mkdir -p etc/systemd/system/multi-user.target.wants
( cd etc/systemd/system/multi-user.target.wants ;  ln -s ../regenerate-ssh-host-keys.service . )

mkdir -p ${S_BUILD_ROOT}/data
cd ${S_BUILD_ROOT}/data
cp -r ${WORKDIR}/files/data/* .
# rk322x is too slow for the usual default patch
if [ "$1" = "rockchip_rk322x" ]; then
  cp vcvrack-v1/generative-02.vcv vcvrack-v1/sonaremin.vcv
fi
cp -f vcvrack-v1/sonaremin.vcv config/vcvrack-v1/autosave.vcv
mkdir -p config/qjackctl/backup
mkdir -p myfiles/vcvrack-v1
cp config/qjackctl/qjackctl-patchbay.xml config/qjackctl/backup
mkdir -p config/vcvrack-v1/backup
cp config/vcvrack-v1/settings.json config/vcvrack-v1/backup/settings.json 

cd ${S_BUILD_ROOT}
cd home/sonaremin
tar --numeric-owner -xzf ${S_DOWNLOAD_DIR}/downloads/vcvrack.${2}-v1.tar.gz
mv vcvrack.${2}-v1 vcvrack-v1
rm -f vcvrack-v1/settings.json vcvrack-v1/autosave.vcv vcvrack-v1/template.vcv
ln -s /data/config/vcvrack-v1/settings.json vcvrack-v1/settings.json
cp -f ${S_BUILD_ROOT}/data/config/vcvrack-v1/autosave.vcv vcvrack-v1/autosave.vcv
cp ${WORKDIR}/files/empty-template.vcv vcvrack-v1/template.vcv
cd ../..
chown -R 1000:1000 home/sonaremin/

export KERNEL_VERSION=`ls ${S_BUILD_ROOT}/boot/*Image-* | sed 's,.*Image-,,g' | sort -u`

# hack to get the fsck binaries in properly even in out chroot env
cp -f ${S_BUILD_ROOT}/usr/share/initramfs-tools/hooks/fsck ${S_BUILD_ROOT}/tmp/fsck.org
sed -i 's,fsck_types=.*,fsck_types="vfat ext4",g' ${S_BUILD_ROOT}/usr/share/initramfs-tools/hooks/fsck
chroot ${S_BUILD_ROOT} update-initramfs -c -k ${KERNEL_VERSION}
mv -f ${S_BUILD_ROOT}/tmp/fsck.org ${S_BUILD_ROOT}/usr/share/initramfs-tools/hooks/fsck

cd ${S_BUILD_ROOT}

# post install script per system
if [ -x ${IMAGEBUILDER}/systems/${1}/postinstall.sh ]; then
  ${IMAGEBUILDER}/systems/${1}/postinstall.sh
fi
if [ -x ${IMAGEBUILDER}/systems/${1}/postinstall-focal.sh ]; then
  ${IMAGEBUILDER}/systems/${1}/postinstall-focal.sh
fi

chroot ${S_BUILD_ROOT} ldconfig

cd ${WORKDIR}

umount ${S_BUILD_ROOT}/proc ${S_BUILD_ROOT}/sys ${S_BUILD_ROOT}/dev/pts ${S_BUILD_ROOT}/dev

echo ""
echo "now run create-image.sh ${1} ${2} to build the image"
echo ""
