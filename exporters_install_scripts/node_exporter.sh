#!/bin/bash

id monitoring || useradd -m -s /bin/bash monitoring
mkdir -p /opt/node_exporter/textfile_directory
chown root:monitoring /opt/node_exporter/textfile_directory
chmod 770 /opt/node_exporter/textfile_directory

wget https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz -O /opt/node_exporter/node_exporter
chown root:monitoring /opt/node_exporter/node_exporter
chmod 750 /opt/node_exporter/node_exporter

echo '[Unit]
Description=Prometheus node_exporter
After=network.target

[Service]
Type=simple
ExecStart=/opt/node_exporter/node_exporter --collector.textfile.directory=/opt/node_exporter/textfile_directory
User=monitoring
Restart=always
RestartSec=10
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/node_exporter.service

chmod 644 /etc/systemd/system/node_exporter.service

systemctl daemon-reload
systemctl enable node_exporter.service
systemctl restart node_exporter.service

