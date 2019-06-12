   * [Setup](#setup)
      * [Requirements](#requirements)
         * [Infrastructure](#infrastructure)
            * [DNS A-records:](#dns-a-records)
            * [Instance performance](#instance-performance)
            * [Instance network](#instance-network)
               * [Monitoring server](#monitoring-server)
               * [Monitoring clients](#monitoring-clients)
      * [install](#install)
         * [install docker](#install-docker)
         * [enable docker monitoring and add default log rotation](#enable-docker-monitoring-and-add-default-log-rotation)
         * [clone repo](#clone-repo)
         * [replace variables by needed values in add_variables.sh and run it](#replace-variables-by-needed-values-in-add_variablessh-and-run-it)
         * [add alerts to prometheus config (assign apropriate dashbords links to variables)](#add-alerts-to-prometheus-config-assign-apropriate-dashbords-links-to-variables)
         * [add hosts to prometheus config and enable needed alert configs](#add-hosts-to-prometheus-config-and-enable-needed-alert-configs)
         * [configure firewall to get node_exporter from host system](#configure-firewall-to-get-node_exporter-from-host-system)
         * [run stack (swarm or docker-compose)](#run-stack-swarm-or-docker-compose)
            * [run stack by swarm](#run-stack-by-swarm)
            * [run stack by docker-compose](#run-stack-by-docker-compose)
   * [Add dashboards](#add-dashboards)
      * [change data source then import to grafana](#change-data-source-then-import-to-grafana)
   * [Info](#info)
      * [Our public repo with usefull code](#our-public-repo-with-usefull-code)
   * [Useful commands](#useful-commands)
      * [Dashboards manipulations](#dashboards-manipulations)
         * [update data source to standard value (ready to customize)](#update-data-source-to-standard-value-ready-to-customize)
      * [Services management](#services-management)
         * [down all containers (swarm)](#down-all-containers-swarm)
         * [check running services](#check-running-services)
         * [restart prometheus (swarm)](#restart-prometheus-swarm)
         * [check prometheus logs (swarm)](#check-prometheus-logs-swarm)
         * [reload prometheus](#reload-prometheus)
   * [Get binary exporters from docker containers images if no in repository](#get-binary-exporters-from-docker-containers-images-if-no-in-repository)

# Setup

## Requirements

### Infrastructure

#### DNS A-records:

~~~~
prometheus.my_domain.com
alertmanager.my_domain.com
grafana.my_domain.com
~~~~

#### Instance performance

Minimal:

~~~~
CPU: 1 core
RAM: 1 Gib
Disk: 40 Gib - regular persistent disk mounted to "/data" without destroy in case of instance delete
Network: static IP address accessible from Internet
~~~~

#### Instance network

##### Monitoring server

Next ports and protocols should be allowed:

~~~~
INPUT:
80,443 TCP - from Internet

OUTPUT:
All TCP/UDP
All ICMP
~~~~

##### Monitoring clients

Next ports and protocols should be allowed:

~~~~
INPUT
9100-9999 TCP - from "Monitoring server"
~~~~

## install

### install docker

~~~~
https://docs.docker.com/install/linux/docker-ce/ubuntu/
~~~~

### enable docker monitoring and add default log rotation

~~~~
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
~~~~

### clone repo

~~~~
mkdir -p /data/monitoring
git clone https://github.com/shalb-docker/prometheus.git /data/monitoring/prometheus
chmod 750 /data/monitoring/prometheus/
~~~~

### replace variables by needed values in add_variables.sh and run it

~~~~
apt install apache2-utils
cd /data/monitoring/prometheus
cp -a add_variables.sh.example add_variables.sh
editor ./add_variables.sh
cat secrets.example > secrets
editor secrets
bash ./add_variables.sh
mkdir prometheus/storage/
mkdir grafana/storage/
mkdir alertmanager/storage/
chmod -R 777 */storage/
~~~~

### add alerts to prometheus config (assign apropriate dashbords links to variables)

~~~~
cp -a add_prometheus_alerts.sh.example add_prometheus_alerts.sh
editor add_prometheus_alerts.sh
bash add_prometheus_alerts.sh
~~~~

### add hosts to prometheus config and enable needed alert configs

~~~~
editor prometheus/configs/prometheus.yml
~~~~

### configure firewall to get node_exporter from host system

~~~~
iptables -I INPUT -s 172.16.0.0/12 -p tcp -m state --state NEW -m tcp --dport 9100 -j ACCEPT
~~~~

### run stack (swarm or docker-compose)

~~~~
mkdir -p ./prometheus/storage
chmod 777 ./prometheus/storage
mkdir -p ./grafana/storage
chmod 777 ./grafana/storage
~~~~

#### run stack by swarm

~~~~
docker swarm init |& tee swarm
docker stack deploy -c docker-compose.yml monitoring
~~~~

#### run stack by docker-compose

##### install docker-compose

~~~~
apt install docker-compose
# or
curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
~~~~

##### insall and run as service

~~~~
cp docker_monitoring.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable docker_monitoring.service
systemctl restart docker_monitoring.service
chmod -R 777 */storage/
systemctl restart docker_monitoring.service
journalctl -f -u docker_monitoring.service
~~~~

# Add dashboards

## change data source then import to grafana

~~~~
mkdir -p tmp/
cp grafana/dashboards/* tmp/
sed -i 's/MY_DATA_SOURCE/YOUR_PROMETHEUS_DATA_SOURCE_HERE/g' tmp/*.json
~~~~

# Info

## Our public repo with usefull code

https://github.com/shalb-docker?tab=repositories

# Useful commands

## Dashboards manipulations

### update data source to standard value (ready to customize)

~~~~
sed -i 's/Shalb prometheus/MY_DATA_SOURCE/g' monit_exporter.json
~~~~

## Services management

### down all containers (swarm)

~~~~
docker stack rm monitoring
~~~~

### check running services

~~~~
docker service ls
~~~~

### restart prometheus (swarm)

~~~~
docker service update monitoring_prometheus --force
~~~~

### check prometheus logs (swarm)

~~~~
docker service logs -f --tail 10 monitoring_prometheus
~~~~

### reload prometheus

~~~~
prometheus_reload.sh
~~~~

# Get binary exporters from docker containers images if no in repository

~~~~
# example composer config to get containers:
mkdir exporters && cd exporters
echo "
version: '2'

services:
  nginx-prometheus-exporter:
    image: nginx/nginx-prometheus-exporter:0.3.0
    container_name: nginx-prometheus-exporter

  php-fpm-exporter:
    image: bakins/php-fpm-exporter:v0.5.0
    container_name: php-fpm-exporter

  memcached-exporter:
    image: quay.io/prometheus/memcached-exporter:v0.5.0
    container_name: memcached-exporter

  elasticsearch-exporter:
    image: justwatch/elasticsearch_exporter:1.0.2
    container_name: elasticsearch-exporter

  cadvisor-exporter:
    image: google/cadvisor:v0.33.0
    container_name: cadvisor-exporter

  redis-exporter:
    image: oliver006/redis_exporter:v0.33.0
    container_name: redis-exporter

  postgres-exporter:
    image: wrouesnel/postgres_exporter:v0.4.7
    container_name: postgres-exporter

" > docker-compose.yml

# run my_container a least once, find container_id via: docker ps -a | grep my_container
# create containers (do Ctrl+C after creation):
exporter="postgres-exporter"
docker-compose up ${exporter}

# find needed container:
container_id=$(docker ps -a | grep ${exporter} | awk '{print $1}')

# copy file from container
rm -rf my_container
mkdir my_container && cd my_container
docker cp ${container_id}:/ ./

# find needed binary in ./, copy it to playbook or to needed host
~~~~
