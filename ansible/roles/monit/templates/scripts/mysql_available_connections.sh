#!/bin/bash

# This file is managed by Ansible, don't make changes here - they will be overwritten.

set -e

# check number of available mysql connections

usage="usage: $0 min_available_connections_percent"

if [ -z $1 ]; then
    echo $usage
    exit 1
fi

min_available_connections_percent=$1
max_con_num=$(mysql --defaults-extra-file=/root/.my.cnf -e 'SHOW GLOBAL VARIABLES LIKE "max_connections";' | tail -n1 | awk '{print $2}')

min_available_connections=$((${max_con_num}*${min_available_connections_percent}/100))

current_con_num=$(mysql --defaults-extra-file=/root/.my.cnf -e 'SHOW STATUS WHERE `Variable_name` = "Threads_connected";' | tail -n1 | awk '{print $2}')

available_connections=$(($max_con_num - $current_con_num))

if [ "$available_connections" -lt "$min_available_connections" ]
    then echo "Available_connections: $available_connections less than ${min_available_connections_percent}% from max_connections: $max_con_num"
        exit 1
    else echo "Available_connections: $available_connections max_connections: $max_con_num"
fi

