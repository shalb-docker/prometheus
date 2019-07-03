#!/bin/bash

_apt_opts="sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
_apt_install_cmd="${_apt_opts} install"

sudo apt-get update

sudo chown -R root:root /tmp/root_sync_preinstall
sudo rsync -av /tmp/root_sync_preinstall/ /

# Monitoring configuration
sudo ${_apt_install_cmd} wget python
sudo useradd -m -s /bin/bash monitoring

## node_exporter
sudo mkdir -p /home/monitoring/node_exporter/textfile_directory
sudo chown root:monitoring /home/monitoring/node_exporter/textfile_directory
sudo chmod 770 /home/monitoring/node_exporter/textfile_directory

wget https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz -O - | tar -xz
sudo mv node_exporter-0.16.0.linux-amd64/node_exporter /usr/local/bin/node_exporter
rm -rf node_exporter-0.16.0.linux-amd64/
sudo chown root:monitoring /usr/local/bin/node_exporter

sudo chmod 750 /usr/local/bin/node_exporter
sudo chmod 644 /etc/systemd/system/node_exporter.service
sudo chown root:root /etc/systemd/system/node_exporter.service

sudo systemctl daemon-reload
sudo systemctl enable node_exporter.service
sudo systemctl restart node_exporter.service

## monit
wget https://mmonit.com/monit/dist/binary/5.21.0/monit-5.21.0-linux-x64.tar.gz
tar -xzf monit-*-linux-x64.tar.gz
sudo mv monit-*/bin/monit /usr/bin/monit
rm -rf monit-*
sudo chmod 755 /usr/bin/monit
sudo chown root:root /usr/bin/monit

sudo mkdir -p /etc/monit.d
sudo mkdir -p /var/log/monit
sudo mkdir -p /root/monit/run
sudo mkdir -p /root/monit/scripts_tmp

sudo chmod 600 /etc/monitrc
sudo chown root:root /etc/monitrc

sudo systemctl daemon-reload
sudo systemctl enable monit.service
sudo systemctl restart monit.service

## monit_collector
sudo chmod 750 /usr/local/bin/monit_collector.py

sudo touch /var/log/monit_collector.log
sudo chown -R root:monitoring /var/log/monit_collector.log
sudo chmod 664 /var/log/monit_collector.log

sudo chmod 640 /usr/local/bin/monit_collector.py.conf
sudo chown -R root:monitoring /usr/local/bin/monit_collector.py*

sudo chmod 644 /etc/systemd/system/monit_collector.service
sudo chown root:root /etc/systemd/system/monit_collector.service

sudo systemctl daemon-reload
sudo systemctl enable monit_collector.service
sudo systemctl restart monit_collector.service

## add crons
sudo chmod 750 /usr/local/bin/monit_not_running.sh
sudo chown root:root /usr/local/bin/monit_not_running.sh

sudo chmod 750 /usr/local/bin/check_monit_collector_exception.py
sudo chown root:root /usr/local/bin/check_monit_collector_exception.py


## monit check scripts
sudo chmod 750 /usr/local/scripts/monit/create_network_interfaces_checks.sh
sudo chown root:root /usr/local/scripts/monit/create_network_interfaces_checks.sh

sudo chmod 750 /usr/local/scripts/monit/create_mounts_checks.py
sudo chown root:root /usr/local/scripts/monit/create_mounts_checks.py

sudo chmod 750 /usr/local/scripts/monit/monit_config_update.sh
sudo chown root:root /usr/local/scripts/monit/monit_config_update.sh

sudo chmod 750 /usr/local/bin/monit_collector_alert.sh
sudo chown root:root /usr/local/bin/monit_collector_alert.sh

sudo chmod 750 /usr/local/scripts/monit/file_system_writable.sh
sudo chown root:root /usr/local/scripts/monit/file_system_writable.sh

