#!/bin/bash

# {{ ansible_managed }}

set -e

# check number of fpm threads

usage="usage: $0 min_available_childrens_percent config_file"

if [ -z $1 ]; then
  echo $usage
  exit 1
fi

config_file=$2

min_available_childrens_percent=$1
max_childrens=$(grep -r "^pm.max_children =" $config_file | awk '{print $3}')

min_available_childrens=$((${max_childrens}*${min_available_childrens_percent}/100))

active_procs=$(curl 127.0.0.1/fpm_status 2>/dev/null | grep "^active processes:" | awk '{print $3}')

available_childrens=$(($max_childrens - $active_procs))

echo $available_childrens

if [ "$available_childrens" -lt "$min_available_childrens" ]; then
  exit 1
fi

