#!/bin/bash

file="{{ monit_textfile_directory }}monit.prom"
string='node_monit{type="monit",name="monit_not_running"} 1'

monit_procs=$( ps aux | grep -v grep | grep /usr/bin/monit | wc -l )

if [ "$monit_procs" != "1" ]
{% if ansible_service_mgr == "systemd" %}
    then systemctl restart monit
{% else %}
    then /etc/init.d/monit restart
{% endif %}
         echo $string > $file
	 chown {{ monit_monitoring_user }}:{{ monit_monitoring_user }} $file
fi

