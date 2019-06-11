#!/bin/bash

# {{ ansible_managed }}

set -e

log_dir="{{ monit_logs_dir }}"
data_source="$1"
interval="$2"
iterations="$3"

current_date=$(date +%Y_%m_%d_%H_%M_%S)
output="${log_dir}monit_atop_${data_source}_${current_date}.log"

# delete old logs
old_files=$(find $log_dir -mtime +7)

for file in $old_files; do
  rm $file
done

if [[ ! -d "${log_dir}" ]]; then
  echo "log directory: ${log_dir} not exist"
  exit 1
fi

# run atop, try to run again when it crash (floating point exception bug)
for i in $(seq 1 20); do
  atop -w $output $interval $iterations
  if [[ "$?" != "0" ]]
    then atop -w $output $interval $iterations
    else exit 0
  fi
done

