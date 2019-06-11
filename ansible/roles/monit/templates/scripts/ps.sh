#!/bin/bash

# {{ ansible_managed }}

log_dir="{{ monit_logs_dir }}"
data_source="$1"

current_date=$(date +%Y_%m_%d_%H_%M_%S)
output="${log_dir}monit_ps_${data_source}_${current_date}.log"

# delete old logs
old_files=$(find $log_dir -type f -mtime +7)

for file in $old_files; do
  rm $file
done

# run ps
ps aux > $output

