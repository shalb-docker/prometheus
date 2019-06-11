#!/bin/bash

# {{ ansible_managed }}

# save mysql processlist

log_dir="/var/log/monit/"
log_dir="{{ monit_logs_dir }}"
if [[ ! -d "${log_dir}" ]]; then
  echo "log directory: ${log_dir} not exist"
  exit 1
fi

data_source="$1"
interval="$2"
number_of_iterations="$3"

for i in $(seq 1 $number_of_iterations); do
    current_date=$(date +%Y_%m_%d_%H_%M_%S)
    output="${log_dir}monit_mysql_processlist_${data_source}_${current_date}.log"
    mysql --defaults-extra-file=/root/.my.cnf -e 'show full processlist' > $output
	sleep $interval
done

