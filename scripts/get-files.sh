#!/bin/bash
#
# please run this script to fetch some prebuilt files from various github releases before starting to build images

if [ "$#" != "1" ]; then
  echo ""
  echo "usage: $0 arch"
  echo ""
  echo "arch can be: armv7l"
  echo "             aarch64"
  echo "             all"
  echo ""
  echo "examples: $0 aarch64"
  echo "          $0 all"
  echo ""
  exit 1
fi

cd `dirname $0`/..

# create downloads dir
export S_DOWNLOAD_DIR=/compile/local/sonaremin-download
mkdir -p $S_DOWNLOAD_DIR

# exit on errors
set -e

# version info
vcvrack_v1_release_version="v1.1.6_10"
raveloxmidi_release_version="0.10.3"
xrdp_release_version="0.9.16"
xorgxrdp_release_version="0.2.16"

# get precompiled vcvrack
if [ "$1" = "all" ] || [ "$1" = "armv7l" ]; then
  wget https://github.com/hexdump0815/vcvrack-dockerbuild-v1/releases/download/${vcvrack_v1_release_version}/vcvrack.armv7l-v1.tar.gz -O ${S_DOWNLOAD_DIR}/vcvrack.armv7l-v1.tar.gz
fi

if [ "$1" = "all" ] || [ "$1" = "aarch64" ]; then
  wget https://github.com/hexdump0815/vcvrack-dockerbuild-v1/releases/download/${vcvrack_v1_release_version}/vcvrack.aarch64-v1.tar.gz -O ${S_DOWNLOAD_DIR}/vcvrack.aarch64-v1.tar.gz
fi

# get precompiled raveloxmidi
if [ "$1" = "all" ] || [ "$1" = "armv7l" ]; then
  wget https://github.com/hexdump0815/raveloxmidi-build/releases/download/${raveloxmidi_release_version}/opt-raveloxmidi-v${raveloxmidi_release_version}-focal-armv7l.tar.gz ${S_DOWNLOAD_DIR}/opt-raveloxmidi-focal-armv7l.tar.gz
fi

if [ "$1" = "all" ] || [ "$1" = "aarch64" ]; then
  wget https://github.com/hexdump0815/raveloxmidi-build/releases/download/${raveloxmidi_release_version}/opt-raveloxmidi-v${raveloxmidi_release_version}-focal-aarch64.tar.gz ${S_DOWNLOAD_DIR}/opt-raveloxmidi-focal-aarch64.tar.gz
fi

# get precompiled xrdp and xorgxrdp
if [ "$1" = "all" ] || [ "$1" = "armv7l" ]; then
  wget https://github.com/hexdump0815/xrdp-xorgxrdp-build/releases/download/xrdp-v${xrdp_release_version}/opt-xrdp-${xrdp_release_version}-focal-armv7l.tar.gz ${S_DOWNLOAD_DIR}/opt-xrdp-focal-armv7l.tar.gz
  wget https://github.com/hexdump0815/xrdp-xorgxrdp-build/releases/download/xorgxrdp-v${xorgxrdp_release_version}/xorgxrdp-${xorgxrdp_release_version}-focal-armv7l.tar.gz ${S_DOWNLOAD_DIR}/xorgxrdp-focal-armv7l.tar.gz
fi

if [ "$1" = "all" ] || [ "$1" = "aarch64" ]; then
  wget https://github.com/hexdump0815/xrdp-xorgxrdp-build/releases/download/xrdp-v${xrdp_release_version}/opt-xrdp-${xrdp_release_version}-focal-aarch64.tar.gz ${S_DOWNLOAD_DIR}/opt-xrdp-focal-aarch64.tar.gz
  wget https://github.com/hexdump0815/xrdp-xorgxrdp-build/releases/download/xorgxrdp-v${xorgxrdp_release_version}/xorgxrdp-${xorgxrdp_release_version}-focal-aarch64.tar.gz ${S_DOWNLOAD_DIR}/xorgxrdp-focal-aarch64.tar.gz
fi
