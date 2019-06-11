#!/bin/bash

# {{ ansible_managed }}

set -e

# save mysql processlist

log_dir="{{ monit_logs_dir }}"
if [[ ! -d "${log_dir}" ]]; then
  echo "log directory: ${log_dir} not exist"
  exit 1
fi

data_source="$1"

current_date=$(date +%Y_%m_%d_%H_%M)
output="${log_dir}monit_apache_status_${data_source}_${current_date}.html"

{% if services.get('apache') %}
curl 127.0.0.1:{{ services['apache']['port'] }}/server-status > $output 2>/dev/null
{% endif %}

