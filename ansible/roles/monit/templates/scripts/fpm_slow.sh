#!/bin/bash

set -e

# check number of fpm threads

my_tmp_dir="{{ monit_scripts_tmp }}"

log_file=$1
my_name=$2
log_file_size_current=$(du -b $log_file | awk '{print $1}')

if [ ! -f "${my_tmp_dir}fpm_slow.sh_${my_name}.tmp" ]
  then log_file_size_old=$log_file_size_current
  else log_file_size_old=$(cat ${my_tmp_dir}fpm_slow.sh_${my_name}.tmp)
fi

echo $log_file_size_current > ${my_tmp_dir}fpm_slow.sh_${my_name}.tmp

if [ $log_file_size_current -gt $log_file_size_old ]; then
  exit 1
fi

