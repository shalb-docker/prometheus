#!/bin/bash

# Basic Readme operations automation
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88 |& grep '9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88' || echo 'Warning - fingerprint nod match, see https://docs.docker.com/install/linux/docker-ce/ubuntu/'

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update

apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose

docker run hello-world |& grep 'Hello from Docker' || echo 'Error - docker hello-world failed'

echo \
'{
    "metrics-addr" : "0.0.0.0:9323",
    "experimental" : true,
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}' > /etc/docker/daemon.json

systemctl restart docker.service

mkdir -p /data/monitoring
git clone https://github.com/shalb-docker/prometheus.git /data/monitoring/prometheus
chmod 750 /data/monitoring/prometheus/

apt install -y apache2-utils
cd /data/monitoring/prometheus

bash ./add_variables.sh

# Create storage directories
mkdir prometheus/storage/
mkdir grafana/storage/
mkdir alertmanager/storage/
chmod -R 777 */storage/

# Install and run as service
cp docker_monitoring.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable docker_monitoring.service
systemctl restart docker_monitoring.service
journalctl -f -u docker_monitoring.service

