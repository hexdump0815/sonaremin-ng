#!/bin/bash

if [ -f /data/config/info.txt ]; then
  . /data/config/info.txt
fi

if [ -f /data/config/sonaremin.txt ]; then
  . /data/config/sonaremin.txt
else
  # start with a hdmi monitor connected (display) or virtual
  DISPLAY_MODE=display
  #DISPLAY_MODE=virtual
  #DISPLAY_MODE=headless
  # which rack version to start automativally
  RACK_VERSION=v1
fi

if [ "$DISPLAY_MODE" = "headless" ]; then
  mv -f /home/sonaremin/rack-${RACK_VERSION}/autosave.vcv /data/config/rack-${RACK_VERSION}/autosave.vcv.display
  STARTUP_FILE="/data/rack-${RACK_VERSION}/sonaremin.vcv"
else
  mv -f /data/config/rack-${RACK_VERSION}/autosave.vcv.display /home/sonaremin/rack-${RACK_VERSION}/autosave.vcv
  if [ ! -s /home/sonaremin/rack-${RACK_VERSION}/autosave.vcv ]; then
    rm -f /home/sonaremin/rack-${RACK_VERSION}/autosave.vcv
  fi
  STARTUP_FILE=""
fi

if [ "$REALTIME_PRIORITY_V1" = "yes" ]; then
  # wait a moment until rack has started up completely
  ( sleep 30 ; sudo /home/sonaremin/bin/set-rtprio-and-cpu-affinity.sh ) &
fi

if [ "$RESET_REALTIME" = "yes" ]; then
  # disable real time prio for rack as it sometimes hangs the system on startup
  # it is reenabled later via the set-rtprio-and-cpu-affinity.sh script
  sed -i.backup-run-rack 's/"realTime":\ true,/"realTime": false,/g' /data/config/rack-v1/settings.json
fi
exec ./Rack -d $STARTUP_FILE
