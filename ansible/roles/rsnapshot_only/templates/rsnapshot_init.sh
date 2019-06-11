#!/bin/bash

for i in $(seq 10)
    do /usr/bin/flock -xw 43200 /tmp/rsnapshot.lock /usr/bin/rsnapshot -c /etc/rsnapshot.conf daily  > /var/log/rsnapshot_daily 2>&1 && /usr/bin/flock -xw 43200 /tmp/rsnapshot.lock /usr/bin/rsnapshot -c /etc/rsnapshot.conf weekly > /var/log/rsnapshot_weekly 2>&1 && /usr/bin/flock -xw 43200 /tmp/rsnapshot.lock /usr/bin/rsnapshot -c /etc/rsnapshot.conf monthly > /var/log/rsnapshot_monthly 2>&1
done

