grep -q 'Raspberry Pi 3 Model B+$' /proc/device-tree/model
if [ "$?" = "0" ]; then
  # raspberry pi 3b plus
  cp /etc/X11/xorg.conf.d.samples/11-modesetting.conf /etc/X11/xorg.conf.d
  cp /etc/X11/xorg.conf.d.samples/13-glamor.conf /etc/X11/xorg.conf.d
  cp /etc/X11/xorg.conf.d.samples/31-monitor-no-dpms.conf /etc/X11/xorg.conf.d
  # check if a custom audio setup exists and use it in that case
  if [ -f /data/config/custom/audio-setup.sh ]; then
    . /data/config/custom/audio-setup.sh
  else
    cp /data/config/qjackctl/QjackCtl.conf-raspberrypi /data/config/qjackctl/QjackCtl.conf
    ( sleep 15; AUDIO_DEVICE=`aplay -l | grep "bcm2835 ALSA \[bcm2835 ALSA\]" | awk '{print $2}' | sed 's,:,,g'`; if [ "$AUDIO_DEVICE" != "" ]; then amixer -c ${AUDIO_DEVICE} set PCM 0 ; fi ) &
  fi
  echo "SYSTEM_MODEL=raspberrypi" > /data/config/info.txt
  echo "SYSTEM_MODEL_DETAILED=raspberrypi_3_b_plus" >> /data/config/info.txt
  # limit the cpu clock to avoid overheating
  # possible values: cat /sys/devices/system/cpu/cpufreq/policy?/scaling_available_frequencies
  #echo MAX_CPU_CLOCK=1200000 >> /data/config/info.txt
  # set the cpu cores rack and jack should run on - we avoid cpu0 as it has to deal
  # more with irq handling etc. - used in set-rtprio-and-cpu-affinity.sh
  echo DESIRED_CPU_AFFINITY=2,3 >> /data/config/info.txt
  echo DESIRED_CPU_AFFINITY_JACK=1 >> /data/config/info.txt
  # allow to disable certain cpu cores to reduce the heat created by the cpu the sonaremin
  # should be fine with 3 out of 4 cores for instance ... this is a space separated list
  echo DISABLE_CPU_CORES=\"\" >> /data/config/info.txt
  # change to vt8 before starting the x server
  echo CHVT="true" >> /data/config/info.txt
fi
