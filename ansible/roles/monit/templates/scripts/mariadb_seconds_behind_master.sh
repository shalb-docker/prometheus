#!/bin/bash                                                                                                                   

# {{ ansible_managed }}

set -e

# Script to check MySQL replication state
# $1 lag in seconds for alert                                                                                               
# $2 lag in seconds for critical
# Example /usr/local/bin/check_mysql_cluster.sh 300

alert_sec=$1

if [[ "$alert_sec" == "" ]]; then
    echo "Please provide first argument"; exit 1
fi

result=$(mysql --defaults-file=/root/.my.cnf  -e 'show all slaves status \G'  | grep Seconds_Behind_Master | awk '{print$2}')
for comm in $result; do
    echo "Replication lag, Seconds_Behind_Master: $comm"
    if [ "$comm" == "NULL" ]; then
        echo "Replication lag, Seconds_Behind_Master: $comm"; exit 1
    fi
    if [ $comm -gt $alert_sec ]; then
        echo "Replication lag, Seconds_Behind_Master: $comm"; exit 1
    fi
done

exit 0

