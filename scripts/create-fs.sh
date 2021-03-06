#!/bin/bash

cd `dirname $0`/..
export WORKDIR=`pwd`

export S_BUILD_ROOT=/compile/local/sonaremin-root
export S_DOWNLOAD_DIR=/compile/local/sonaremin-download

if [ -d ${S_BUILD_ROOT} ]; then
  echo ""
  echo "S_BUILD_ROOT ${S_BUILD_ROOT} already exists - giving up for safety reasons ..."
  echo ""
  exit 1
fi

if [ ! -d ${S_DOWNLOAD_DIR} ]; then
  echo ""
  echo "download dir ${S_DOWNLOAD_DIR} does not exists - please run get-files.sh first ..."
  echo ""
  exit 1
fi

if [ -d ${WORKDIR}/../imagebuilder/systems ]; then
  # path to the cloned imagebuilder framework
  cd ${WORKDIR}/../imagebuilder
  export IMAGEBUILDER=`pwd`
else
  echo ""
  echo "please clone the main branch of https://github.com/hexdump0815/imagebuilder to ${WORKDIR}/../imagebuilder first"
  echo ""
  echo "giving up for now"
  echo ""
  exit 1
fi

cd ${WORKDIR}

. scripts/args-and-arch-check-functions.sh

export DOWNLOAD_DIR=/compile/local/imagebuilder-download

if [ ! -d ${DOWNLOAD_DIR} ]; then
  echo ""
  echo "download dir ${DOWNLOAD_DIR} does not exists - please run \"${IMAGEBUILDER}/scripts/get-files.sh $1 $2 focal\" first ... then rerun this script as you just did"
  echo ""
  exit 1
fi

if [ "${1}" != "$(cat ${DOWNLOAD_DIR}/system.txt)" ] || \
   [ "${2}" != "$(cat ${DOWNLOAD_DIR}/arch.txt)" ] || \
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

cp ${WORKDIR}/scripts/create-chroot-stage-02.sh ${S_BUILD_ROOT}

mount -o bind /dev ${S_BUILD_ROOT}/dev
mount -o bind /dev/pts ${S_BUILD_ROOT}/dev/pts
mount -t sysfs /sys ${S_BUILD_ROOT}/sys
mount -t proc /proc ${S_BUILD_ROOT}/proc
# TODO: this can most probably go
#cp /proc/mounts ${S_BUILD_ROOT}/etc/mtab  
#cp /etc/resolv.conf ${S_BUILD_ROOT}/etc/resolv.conf 

chroot ${S_BUILD_ROOT} /create-chroot-stage-02.sh

cd ${S_BUILD_ROOT}/

rm -f create-chroot-stage-0?.sh

tar --numeric-owner -xhzf ${DOWNLOAD_DIR}/kernel-${1}-${2}.tar.gz
if [ -f ${DOWNLOAD_DIR}/kernel-mali-${1}-${2}.tar.gz ]; then
  tar --numeric-owner -xhzf ${DOWNLOAD_DIR}/kernel-mali-${1}-${2}.tar.gz
fi

if [ -d ${DOWNLOAD_DIR}/boot-extra-${1} ]; then
  mkdir -p boot/extra
  cp -r ${DOWNLOAD_DIR}/boot-extra-${1}/* boot/extra
fi

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

# the sonaremin uses syslinux with /boot/menu as dir - so remove /boot/extlinux and add /boot/menu per system
rm -rf boot/extlinux

tar --numeric-owner -xzf ${S_DOWNLOAD_DIR}/opt-xrdp-focal-${2}.tar.gz
# unpack this before the extra-files as they bring an adapted config
tar --numeric-owner -xzf ${S_DOWNLOAD_DIR}/xorgxrdp-focal-${2}.tar.gz
tar --numeric-owner -xzf ${S_DOWNLOAD_DIR}/opt-raveloxmidi-focal-${2}.tar.gz

tar --numeric-owner -xzf ${DOWNLOAD_DIR}/opt-mesa-focal-${2}.tar.gz

if [ -f ${DOWNLOAD_DIR}/opengl-${1}-${2}.tar.gz ]; then
  tar --numeric-owner -xzf ${DOWNLOAD_DIR}/opengl-${1}-${2}.tar.gz
fi
if [ -f ${DOWNLOAD_DIR}/opengl-fbdev-${1}-${2}.tar.gz ]; then
  tar --numeric-owner -xzf ${DOWNLOAD_DIR}/opengl-fbdev-${1}-${2}.tar.gz
fi
if [ -f ${DOWNLOAD_DIR}/opengl-wayland-${1}-${2}.tar.gz ]; then
  tar --numeric-owner -xzf ${DOWNLOAD_DIR}/opengl-wayland-${1}-${2}.tar.gz
fi
if [ -f ${DOWNLOAD_DIR}/gl4es-${2}-${3}.tar.gz ]; then
  tar --numeric-owner -xzf ${DOWNLOAD_DIR}/gl4es-${2}-${3}.tar.gz
fi

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
  cp rack-v1/generative-02.vcv rack-v1/sonaremin.vcv
fi
cp -f rack-v1/sonaremin.vcv config/rack-v1/autosave.vcv
mkdir -p config/qjackctl/backup
mkdir -p myfiles/rack-v1
cp config/qjackctl/qjackctl-patchbay.xml config/qjackctl/backup
mkdir -p config/rack-v1/backup
cp config/rack-v1/settings.json config/rack-v1/backup/settings.json 

cd ${S_BUILD_ROOT}
cd home/sonaremin
tar --numeric-owner -xzf ${S_DOWNLOAD_DIR}/rack.${2}-v1.tar.gz
mv rack.${2}-v1 rack-v1
rm -f rack-v1/settings.json rack-v1/autosave.vcv rack-v1/template.vcv
ln -s /data/config/rack-v1/settings.json rack-v1/settings.json
cp -f ${S_BUILD_ROOT}/data/config/rack-v1/autosave.vcv rack-v1/autosave.vcv
cp ${WORKDIR}/files/empty-template.vcv rack-v1/template.vcv
cd ../..
chown -R 1000:1000 home/sonaremin/

cd ${S_BUILD_ROOT}

# add support for self built fresher mesa
if [ "${2}" = "armv7l" ]; then
  echo "LD_LIBRARY_PATH=/opt/mesa/lib/arm-linux-gnueabihf/dri:/usr/lib/arm-linux-gnueabihf/dri" > etc/environment.d/50-opt-mesa.conf
  echo "LIBGL_DRIVERS_PATH=/opt/mesa/lib/arm-linux-gnueabihf/dri:/usr/lib/arm-linux-gnueabihf/dri" >> etc/environment.d/50-opt-mesa.conf
  echo "GBM_DRIVERS_PATH=/opt/mesa/lib/arm-linux-gnueabihf/dri:/usr/lib/arm-linux-gnueabihf/dri" >> etc/environment.d/50-opt-mesa.conf
  echo "/opt/mesa/lib/arm-linux-gnueabihf" > etc/ld.so.conf.d/aaa-mesa.conf
elif [ "${2}" = "aarch64" ]; then
  echo "LD_LIBRARY_PATH=/opt/mesa/lib/aarch64-linux-gnu/dri:/usr/lib/aarch64-linux-gnu/dri" > etc/environment.d/50-opt-mesa.conf
  echo "LIBGL_DRIVERS_PATH=/opt/mesa/lib/aarch64-linux-gnu/dri:/usr/lib/aarch64-linux-gnu/dri" >> etc/environment.d/50-opt-mesa.conf
  echo "GBM_DRIVERS_PATH=/opt/mesa/lib/aarch64-linux-gnu/dri:/usr/lib/aarch64-linux-gnu/dri" >> etc/environment.d/50-opt-mesa.conf
  echo "/opt/mesa/lib/aarch64-linux-gnu" > etc/ld.so.conf.d/aaa-mesa.conf
fi

# add some sonaremin version info as /etc/sonaremin-info
SONAREMIN_VERSION=$(cd ${WORKDIR}; git rev-parse --verify HEAD)
echo ${1} ${2} sonaremin ${SONAREMIN_VERSION} > ${S_BUILD_ROOT}/etc/sonaremin-info

# copy postinstall files into the build root if there are any
if [ -d ${DOWNLOAD_DIR}/postinstall-${1} ]; then
  cp -r ${DOWNLOAD_DIR}/postinstall-${1} ${S_BUILD_ROOT}/postinstall
fi

# post install script per system
if [ -x ${IMAGEBUILDER}/systems/${1}/postinstall.sh ]; then
  ${IMAGEBUILDER}/systems/${1}/postinstall.sh ${1} ${2} focal
fi

# post install script which is run chrooted per system
if [ -x ${IMAGEBUILDER}/systems/${1}/postinstall-chroot.sh ]; then
  cp ${IMAGEBUILDER}/systems/${1}/postinstall-chroot.sh ${S_BUILD_ROOT}/postinstall-chroot.sh
  chroot ${S_BUILD_ROOT} /postinstall-chroot.sh ${1} ${2} focal
  rm -f ${S_BUILD_ROOT}/postinstall-chroot.sh
fi

# cleanup postinstall files
if [ -d ${S_BUILD_ROOT}/postinstall ]; then
  rm -rf ${S_BUILD_ROOT}/postinstall
fi

chroot ${S_BUILD_ROOT} ldconfig

export KERNEL_VERSION=`ls ${S_BUILD_ROOT}/boot/*Image-* | sed 's,.*Image-,,g' | sort -u`

# hack to get the fsck binaries in properly even in out chroot env
cp -f ${S_BUILD_ROOT}/usr/share/initramfs-tools/hooks/fsck ${S_BUILD_ROOT}/tmp/fsck.org
sed -i 's,fsck_types=.*,fsck_types="vfat ext4",g' ${S_BUILD_ROOT}/usr/share/initramfs-tools/hooks/fsck
chroot ${S_BUILD_ROOT} update-initramfs -c -k ${KERNEL_VERSION}
mv -f ${S_BUILD_ROOT}/tmp/fsck.org ${S_BUILD_ROOT}/usr/share/initramfs-tools/hooks/fsck

cd ${WORKDIR}

umount ${S_BUILD_ROOT}/proc ${S_BUILD_ROOT}/sys ${S_BUILD_ROOT}/dev/pts ${S_BUILD_ROOT}/dev

echo ""
echo "now run create-image.sh ${1} ${2} to build the image"
echo ""
