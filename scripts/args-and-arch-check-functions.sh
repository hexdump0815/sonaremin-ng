# this file is supposed to be sourced by the create-fs and create-image shell scripts

if [ "$#" != "2" ]; then
  echo ""
  echo "usage: $0 system arch"
  echo ""
  echo "possible system options:"
  for i in $(ls ${IMAGEBUILDER}/systems | grep -E 'allwinner_h6|amlogic_gx|amlogic_m8|odroid_u3|odroid_xu4|raspberry_pi_3|raspberry_pi_4|rockchip_rk33xx|tinkerboard'); do
    echo -n "- "$i" - "; cat ${IMAGEBUILDER}/systems/$i/arch.txt
  done
  echo ""
  echo "possible arch options:"
  echo "- armv7l - 32bit"
  echo "- aarch64 - 64bit"
  echo ""
  echo "example: $0 odroid_u3 armv7l"
  echo ""
  exit 1
fi

if [ $(uname -m) != ${2} ]; then
  echo ""
  echo "the target arch ${2} is not the same arch this system is running on: $(uname -m) - giving up"
  echo ""
  exit 1
fi
