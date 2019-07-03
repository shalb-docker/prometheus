#!/bin/bash

# install dependencies
apt update
apt install -y wget python


# node_exporter install
id monitoring || useradd -m -s /bin/bash monitoring
mkdir -p /home/monitoring/node_exporter/textfile_directory
chown root:monitoring /home/monitoring/node_exporter/textfile_directory
chmod 770 /home/monitoring/node_exporter/textfile_directory

wget https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz -O - | tar -xz
mv node_exporter-0.16.0.linux-amd64/node_exporter /usr/local/bin/node_exporter
rm -rf node_exporter-0.16.0.linux-amd64/
chown root:monitoring /usr/local/bin/node_exporter
chmod 750 /usr/local/bin/node_exporter

echo '[Unit]
Description=Prometheus node_exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=/home/monitoring/node_exporter/textfile_directory
User=monitoring
Restart=always
RestartSec=10
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/node_exporter.service

chmod 644 /etc/systemd/system/node_exporter.service
chown root:root /etc/systemd/system/node_exporter.service

systemctl daemon-reload
systemctl enable node_exporter.service
systemctl restart node_exporter.service


# monit install
#wget https://mmonit.com/monit/dist/binary/5.21.0/monit-5.21.0-linux-x86.tar.gz -O - | tar -xz
#mv monit-5.21.0/bin/monit /usr/bin/monit
#rm -rf monit-5.21.0/
wget https://mmonit.com/monit/dist/binary/5.21.0/monit-5.21.0-linux-x64.tar.gz -O /usr/bin/monit
chmod 755 /usr/bin/monit
chown root:root /usr/bin/monit

echo '[Unit]
Description=Pro-active monitoring utility for unix systems
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/monit -I
ExecStop=/usr/bin/monit quit
ExecReload=/usr/bin/monit reload
Restart=always
RestartSec=10
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/monit.service

chmod 644 /etc/systemd/system/monit.service
chown root:root /etc/systemd/system/monit.service

mkdir -p /etc/monit.d
mkdir -p /var/log/monit
mkdir -p /root/monit/run
mkdir -p /root/monit/scripts_tmp

echo 'set daemon  10
set logfile /var/log/monit/monit.log

set pidfile /root/monit/run/.monit.pid
set idfile /root/monit/.monit.id
set statefile /root/monit/.monit.state

set limits {
  programOutput:     512 B,      # check programs output truncate limit
  sendExpectBuffer:  256 B,      # limit for send/expect protocol test
  fileContentBuffer: 512 B,      # limit for file content test
  httpContentBuffer: 1 MB,       # limit for HTTP content test
  networkTimeout:    10 seconds   # timeout for network I/O
  programTimeout:    10 seconds # timeout for check program
  stopTimeout:       10 seconds  # timeout for service stop
  startTimeout:      10 seconds  # timeout for service start
  restartTimeout:    10 seconds  # timeout for service restart
}

set mmonit http://admin:admin@127.0.0.1:8888/collector

set eventqueue
  basedir /root/monit/eventqueue  # set the base directory where events will be stored
  slots 100                       # optionally limit the queue size

set httpd port 2812 and
    use address localhost  # only accept connection from localhost
    allow localhost        # allow localhost to connect to the server and
    allow admin:"flsdhflhfauhhenEb288370128efhidhkjvbkksfsfvfrgskfjsdfksdfhge73r7"      # require user 'admin' with password

include /etc/monit.d/*.conf
' > /etc/monitrc

echo 'CHECK PROCESS monit-P5-team_noalert MATCHING "/usr/bin/monit"' > /etc/monit.d/monit.conf

chmod 600 /etc/monitrc
chown root:root /etc/monitrc

echo "CHECK SYSTEM $(hostname)" > /etc/monit.d/system.conf

systemctl daemon-reload
systemctl enable monit.service
systemctl restart monit.service


# install monit collector

wget https://raw.githubusercontent.com/shalb-docker/prometheus/master/ansible/roles/monit_collector/files/monit_collector.py -O /usr/local/bin/monit_collector.py
chmod 750 /usr/local/bin/monit_collector.py

touch /var/log/monit_collector.log
chown -R root:monitoring /var/log/monit_collector.log
chmod 664 /var/log/monit_collector.log

echo '{
"host_name":                 "127.0.0.1",
"ip":                        "127.0.0.1",
"daemon":                    false,
"disable_own_alerting_code": true,
"host":                      "127.0.0.1",
"port":                       8888,
"pid_file":                  "/tmp/monit_collector.pid",
"log_level":                 "INFO",
"http_timeout":               1,
"log_file":                  "/var/log/monit_collector.log",
"textfile_directory":        "/home/monitoring/node_exporter/textfile_directory/monit.prom",
"opsgenie_default_team":     "SHALB Support",
"opsgenie_default_priority": "P3",
"opsgenie_api_key":          "GenieKey 00000000-0000-0000-0000-000000000000",
"opsgenie_url":              "https://api.opsgenie.com",

"message":                   "monit | {host_name} | {service}",
"help":                      "Go to host and check alert description in monit config: grep -r {service} /etc/monit*",
"access":                    "https://my-wiki.example.com/monitoring#monitoring-Access",
"grafana":                   "https://grafana.example.com/ .* node={host_name}.example.com:9100 .*",
"prometheus":                "https://prometheus.example.com/ .* {host_name}/{service} .*",

"alert_provider":            "opsgenie_api",

"alert_providers": [
    "opsgenie_api",
    "opsgenie_lamp"
],

"labels": [
    "port_protocol",
    "port_hostname",
    "port_type",
    "fstype",
    "port_portnumber"
],

"excluded_keys": [
    "status_hint",
    "collected_usec",
    "monitormode",
    "onreboot",
    "pendingaction",
    "checksum_type",
    "euid",
    "gid",
    "pid",
    "ppid",
    "uid",
    "memory_kilobyte",
    "memory_percent",
    "cpu_percent",
    "program_output",
    "port_portnumber",
    "name",
    "fsflags"
],

"types": [
    "filesystem",
    "directory",
    "file",
    "process",
    "remote_host",
    "system",
    "fifo",
    "program",
    "network"
],

"test_alert":                false,
"test_alert_name":           "test_alert",
"test_alert_priority":       "P5",
"test_alert_team":           "test",
"test_alert_message":        "test alert",
"test_alert_life_time":       5

}
' > /usr/local/bin/monit_collector.py.conf
chmod 640 /usr/local/bin/monit_collector.py.conf
chown -R root:monitoring /usr/bin/monit_collector.py*

echo '[Unit]
Description=Monit collector
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/monit_collector.py
User=monitoring
Restart=always
RestartSec=15
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/monit_collector.service

chmod 644 /etc/systemd/system/monit_collector.service
chown root:root /etc/systemd/system/monit_collector.service

systemctl daemon-reload
systemctl enable monit_collector.service
systemctl restart monit_collector.service


# add crons
echo '* * * * * monitoring date > /tmp/monit_cron_test' > /etc/cron.d/cron_test
echo '* * * * * root /usr/local/bin/monit_not_running.sh > /dev/null 2>&1' > /etc/cron.d/monit_not_running

echo '#!/bin/bash

file="/home/monitoring/node_exporter/textfile_directory/monit.prom"
string='node_monit{type="monit",name="monit_not_running"} 1'

monit_procs=$( ps aux | grep -v grep | grep /usr/bin/monit | wc -l )

if [ "$monit_procs" != "1" ]
    then /etc/init.d/monit restart
         echo $string > $file
         chown monitoring:monitoring $file
fi

file_monit_procs="/home/monitoring/node_exporter/textfile_directory/number_of_monit_processes.prom"
string_monit_procs="node_number_of_monit_processes ${monit_procs}"
echo $string_monit_procs > $file_monit_procs
' > /usr/local/bin/monit_not_running.sh

chmod 750 /usr/local/bin/monit_not_running.sh
chown root:root /usr/local/bin/monit_not_running.sh


# add addiional checks

echo '#!/usr/bin/env python

from __future__ import print_function
from __future__ import division
from __future__ import absolute_import
from __future__ import unicode_literals

import os
import json
import sys

file_name = '/var/log/monit_collector.log'
pattern = 'CRITICAL'
results_dir = '/root/scripts_tmp/'
results_file = '{0}{1}.results'.format(results_dir, os.path.split(file_name)[-1])
matched_lines = list()

# get last results
current_file_size = os.stat(file_name)[6]

start_possition = 0
if os.path.isdir(results_dir):
    if os.path.isfile(results_file):
        last_results = json.loads(open(results_file).read())
        last_file_size = last_results['last_file_size']
        if current_file_size > last_file_size:
            start_possition = last_file_size
        elif current_file_size == last_file_size:
            sys.exit()

else:
    os.mkdir(results_dir)

with open(file_name) as f:
    f.seek(start_possition)
    line = f.readline()
    while line:
        if line.find(pattern) != -1:
            matched_lines.append(line.strip())
        line = f.readline()
    current_file_size = f.tell()

results = {
    'last_file_size': current_file_size,
}

json.dump(results, open(results_file, 'w'))

if matched_lines:
    print('Found {0} exceptions:'.format(len(matched_lines)))
    for line in matched_lines:
        print(line)
    sys.exit(1)

' > /usr/local/bin/check_monit_collector_exception.py

chmod 750 /usr/local/bin/check_monit_collector_exception.py
chown root:root /usr/local/bin/check_monit_collector_exception.py


echo '# description: restart cron daemon if not running
CHECK PROCESS cron MATCHING "/usr/sbin/cron"
  IF NOT EXIST FOR 3 CYCLES THEN exec "/bin/systemctl restart cron.service"
  REPEAT EVERY 60 CYCLES
  GROUP cron
' > /etc/monit.d/cron.conf

echo '# description: alert if cron test job not working
CHECK FILE cron_working_file-P3-team_noalert WITH PATH /tmp/monit_cron_test
  IF TIMESTAMP > 80 seconds THEN alert
  IF NOT EXIST FOR 8 CYCLES THEN alert
' > /etc/monit.d/cron_working.conf

echo '# description: restart monit_collector.py daemon if it not running
CHECK PROCESS monit_collector-P3-team_noalert MATCHING "^(.*?python.+)?/usr/local/bin/monit_collector.py"
  IF NOT EXIST FOR 3 CYCLES THEN exec "/bin/systemctl restart monit_collector.service"
  REPEAT EVERY 10 CYCLES
  GROUP monit_collector

# description: create alert if monit_collector.py daemon did no fresh monit.prom data file
CHECK FILE monit_collector_stats_file_to_old-P3-team_noalert WITH PATH /home/monitoring/node_exporter/textfile_directory/monit.prom
  IF TIMESTAMP > 60 seconds THEN exec "/usr/local/bin/monit_collector_alert.sh"
  IF NOT EXIST FOR 6 CYCLES THEN exec "/usr/local/bin/monit_collector_alert.sh"
  GROUP monit_collector

# description: alert if monit_collector log /var/log/monit_collector.log contains exception(s)
CHECK PROGRAM check_monit_collector_exception-P3-team_noalert WITH PATH "/usr/local/bin/check_monit_collector_exception.py" WITH TIMEOUT 60 SECONDS EVERY 30 CYCLES
  IF STATUS != 0 THEN alert
' > /etc/monit.d/monit_collector.conf

echo '# description: restart node_exporter service if it not running
CHECK PROCESS node_exporter-P3-team_noalert MATCHING "/usr/local/bin/node_exporter"
  IF NOT EXIST FOR 1 CYCLES THEN exec "/etc/init.d/node_exporter restart"
  REPEAT EVERY 60 CYCLES
  GROUP node_exporter
' > /etc/monit.d/node_exporter.conf

echo '#!/bin/bash

echo \
"# description: check if link failed
CHECK NETWORK net_lo-P5-team_noalert WITH INTERFACE lo
  IF FAILED LINK THEN alert
" > /etc/monit.d/network_interfaces.conf

dev=$(cat /proc/net/route | grep -E "^[a-zA-Z0-9_]+\s+00000000" | awk "{print $1}" | head -n1)
if [ "$dev" != "" ]; then
    echo \
"# description: check if link failed
CHECK NETWORK net_${dev}-P5-team_noalert WITH INTERFACE ${dev}
  IF FAILED LINK THEN alert
" >> /etc/monit.d/network_interfaces.conf
fi
' > /usr/local/scripts/monit/create_network_interfaces_checks.sh

chmod 750 /usr/local/scripts/monit/create_network_interfaces_checks.sh
chown root:root /usr/local/scripts/monit/create_network_interfaces_checks.sh
/usr/local/scripts/monit/create_network_interfaces_checks.sh

wget https://raw.githubusercontent.com/poc/infrastructure/master/ansible/roles/monit_collector/files/check_monit_collector_exception.py -O /usr/local/scripts/monit/create_mounts_checks.py

chmod 750 /usr/local/scripts/monit/create_mounts_checks.py
chown root:root /usr/local/scripts/monit/create_mounts_checks.py
/usr/local/scripts/monit/create_mounts_checks.py


