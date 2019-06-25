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
mv node_exporter-0.16.0.linux-amd64/node_exporter /usr/bin/node_exporter
rm -rf node_exporter-0.16.0.linux-amd64/
chown root:monitoring /usr/bin/node_exporter
chmod 750 /usr/bin/node_exporter

echo '[Unit]
Description=Prometheus node_exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node_exporter --collector.textfile.directory=/home/monitoring/node_exporter/textfile_directory
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
wget https://github.com/shalb-docker/prometheus/raw/master/ansible/roles/monit/files/monit -O /usr/bin/monit
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
mkdir -p /run
mkdir -p /root/monit/scripts_tmp

echo 'set daemon  10
set logfile /var/log/monit/monit.log

set pidfile /run/.monit.pid
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

wget https://raw.githubusercontent.com/shalb-docker/prometheus/master/ansible/roles/monit_collector/files/monit_collector.py -O /usr/bin/monit_collector.py
chmod 750 /usr/bin/monit_collector.py

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
' > /usr/bin/monit_collector.py.conf
chmod 640 /usr/bin/monit_collector.py.conf
chown -R root:monitoring /usr/bin/monit_collector.py*

echo '[Unit]
Description=Monit collector
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/monit_collector.py
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

