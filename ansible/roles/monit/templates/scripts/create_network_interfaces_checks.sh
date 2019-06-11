#!/bin/bash

echo \
"# description: check if link failed
CHECK NETWORK net_lo-P5-team_noalert WITH INTERFACE lo
  IF FAILED LINK THEN alert
" > /etc/monit.d/network_interfaces.conf

dev=$(cat /proc/net/route | grep -E '^[a-zA-Z0-9_]+\s+00000000' | awk '{print $1}' | head -n1)
if [ "$dev" != "" ]; then
    echo \
"# description: check if link failed
CHECK NETWORK net_${dev}-P5-team_noalert WITH INTERFACE ${dev}
  IF FAILED LINK THEN alert
" >> /etc/monit.d/network_interfaces.conf
fi

