#!/bin/bash

my_tmp_file="{{ monit_scripts_tmp }}log_la.tmp"

if [ ! -f ${my_tmp_file} ]
  then my_previous_la="0"
  else my_previous_la=$(cat ${my_tmp_file})
fi

my_current_la=$(cat /proc/loadavg | cut -d'.' -f -1)

echo $my_current_la > ${my_tmp_file}

if [ "$my_previous_la" -gt "{{ number_of_cores['stdout'] }}" ]
  then exit 0
fi

if [ "$my_current_la" -ge "{{ number_of_cores['stdout'] }}" ]
  then
    flock -xw 1 /tmp/monit_ps.lock -c "{{ monit_scripts_dir }}ps.sh loadavg"
{% if services.get('mysql') %}
    flock -xw 1 /tmp/monit_mysql.lock -c "{{ monit_scripts_dir }}get_mysql_processlist.sh loadavg 1 1"
{% endif %}
fi

