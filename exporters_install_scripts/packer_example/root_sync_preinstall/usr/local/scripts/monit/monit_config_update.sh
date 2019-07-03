#!/bin/bash

/usr/local/scripts/monit/create_mounts_checks.py /etc/monit.d/ > /dev/null 2>&1
/usr/local/scripts/monit/create_network_interfaces_checks.sh > /dev/null 2>&1
echo "CHECK SYSTEM $(hostname)" > /etc/monit.d/system.conf
monit reload

