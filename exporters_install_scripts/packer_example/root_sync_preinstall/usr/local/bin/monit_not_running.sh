#!/bin/bash

file="/home/monitoring/node_exporter/textfile_directory/monit.prom"
string='node_monit{type="monit",name="monit_not_running"} 1'

monit_procs=$( ps aux | grep -v grep | grep /usr/bin/monit | wc -l )

if [ "$monit_procs" != "1" ]
    then systemctl restart monit
         echo $string > $file
fi

