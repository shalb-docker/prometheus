#!/bin/bash                                                                                                                   

# {{ ansible_managed }}

set -e

# Script to check MySQL replication state
# $1 lag in seconds for alert                                                                                               
# Example /usr/local/bin/check_mysql_cluster.sh 300

alert_sec=$1

if [[ "$alert_sec" == "" ]]; then
    echo "alert_sec is not set"; exit 1
fi

mysql --defaults-file=/root/.my.cnf -e 'select USER();' > /dev/null || exit 1

result=$(mysql --defaults-file=/root/.my.cnf -e 'show slave status \G'  | grep Seconds_Behind_Master | awk '{print$2}')
for comm in $result; do
    echo $comm
    if [ "$comm" == "NULL" ]; then
        echo "Alert cluster failed. Active nodes:" $comm; exit 1
    fi
    if [ $comm -gt $alert_sec ]; then
        echo "Alert. Replication lag:" $comm "seconds"; exit 1
    fi
done

exit 0

