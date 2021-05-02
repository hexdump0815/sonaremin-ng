grep -q 'RK3228B MK809IV HDMI Stick$' /proc/device-tree/model
if [ "$?" = "0" ]; then
  # mk809iv
  if [ "$DISPLAY_MODE" = "display" ]; then
    # in display mode we can use mali opengl with the armsoc xorg server
    ln -sf /opt/mali-rk322x-armv7l /opt/libgl
    ln -sf /opt/gl4es-armv7l /opt/gl4es
  else
    # in cese we are not in display mode use mesa software opengl
    # rendering (i.e. no mali and no gl4es) with max 1 thread
    ln -sf /dev/null /opt/libgl
    ln -sf /dev/null /opt/gl4es
    export LP_NUM_THREADS=1
  fi
  cp /data/config/x11/xorg.conf-armsoc /etc/X11/xorg.conf.d/xorg.conf
  # check if a custom audio setup exists and use it in that case
  if [ -f /data/config/custom/audio-setup.sh ]; then
    . /data/config/custom/audio-setup.sh
  else
    cp /data/config/qjackctl/QjackCtl.conf-rk322x /data/config/qjackctl/QjackCtl.conf
    ( sleep 15; AUDIO_DEVICE=`aplay -l | grep "DAC \[USB AUDIO    DAC\]" | awk '{print $2}' | sed 's,:,,g'`; if [ "$AUDIO_DEVICE" != "" ]; then amixer -c ${AUDIO_DEVICE} set PCM 64 ; fi ) &
  fi
  echo "SYSTEM_MODEL=rk322x" > /data/config/info.txt
  echo "SYSTEM_MODEL_DETAILED=mk809iv_tv_stick" >> /data/config/info.txt
  # limit the cpu clock to avoid overheating
  # possible values: cat /sys/devices/system/cpu/cpufreq/policy?/scaling_available_frequencies
  #echo MAX_CPU_CLOCK=1200000 >> /data/config/info.txt
  # set the cpu cores vcvrack and jack should run on - we avoid cpu0 as it has to deal
  # more with irq handling etc. - used in set-rtprio-and-cpu-affinity.sh
  echo DESIRED_CPU_AFFINITY=2,3 >> /data/config/info.txt
  echo DESIRED_CPU_AFFINITY_JACK=1 >> /data/config/info.txt
  # allow to disable certain cpu cores to reduce the heat created by the cpu the sonaremin
  # should be fine with 3 out of 4 cores for instance ... this is a space separated list
  # better do not disable anything on this weak system, set jack affinity to 0 in case of disabling 1 anyway
  #echo DISABLE_CPU_CORES=\"1\" >> /data/config/info.txt
  # change to vt8 before starting the x server
  echo CHVT="true" >> /data/config/info.txt
  # extra addition in front of the LD_LIBRARY_PATH when starting vcvrack
  echo LDLP_PRE_EXTRA="/opt/gl4es" >> /data/config/info.txt
fi
