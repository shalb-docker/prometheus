# Setup

## Requirements

### Infrastructure

#### DNS A-records:

~~~~
prometheus.my_domain.com    A MY_IP_HERE
alertmanager.my_domain.com  A MY_IP_HERE
grafana.my_domain.com       A MY_IP_HERE
# Add grafana.local.my_domain.com in case of aws host
grafana.local.my_domain.com A MY_PRIVATE_IP_HERE

~~~~

#### DNS SPF-records:

Add next TXT records if you need to send emails via postfix-relay:
~~~~
grafana.my_domain.com      TXT "v=spf1 a -all"
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

## Install

### Fast install

~~~~
# Add your secrets (all not commented secrets are mandatory) 
mkdir -p /data/monitoring
git clone https://github.com/shalb-docker/prometheus.git /data/monitoring/prometheus
chmod 750 /data/monitoring/prometheus/
cd /data/monitoring/prometheus/
cat secrets.example > secrets
editor secrets
bash base_install.sh
~~~~

### Explained install

#### Install docker

~~~~
https://docs.docker.com/install/linux/docker-ce/ubuntu/
~~~~

#### Enable docker monitoring and add default log rotation

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

#### Clone repo

~~~~
mkdir -p /data/monitoring
git clone https://github.com/shalb-docker/prometheus.git /data/monitoring/prometheus
chmod 750 /data/monitoring/prometheus/
~~~~

#### Replace variables by needed values in add_variables.sh and run it

~~~~
apt install apache2-utils
cd /data/monitoring/prometheus
# Add your secrets (all not commented secrets are mandatory) 
cat secrets.example > secrets
editor secrets
# Create add_variables.sh script if it not exist
cp -a add_variables.sh.example add_variables.sh
# Copy "*.example" files to "*.custom" and replace appropriate names in 'add_variables.sh' script if any customization needed
editor ./add_variables.sh
# Apply it
bash ./add_variables.sh
# Create storage directories
mkdir prometheus-prod/storage/
mkdir grafana/storage/
mkdir alertmanager/storage/
chmod -R 777 */storage/
# Uncomment or add new files with secrets in '.gitignore' if you have any additional files with secrets
editor .gitignore
~~~~

#### Add hosts to prometheus config and customize

~~~~
cp -a prometheus-prod/configs/prometheus.yml.example prometheus-prod/configs/prometheus.yml
editor prometheus-prod/configs/prometheus.yml
~~~~

#### run stack by docker-compose

##### install docker-compose

~~~~
apt install docker-compose
# or
curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
~~~~

##### install and run as service

~~~~
cp docker_monitoring.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable docker_monitoring.service
systemctl restart docker_monitoring.service
journalctl -f -u docker_monitoring.service
~~~~

# Customization

See 'add_variables.sh' script to add any customization if you need it.

Customization looks like this:
* copy example file and replace 'example' by 'custom' in its name
* change custom file
* replace 'example' by 'custom' in 'add_variables.sh' script for appropriate record
* add new secrets to 'secrets' file, modify appripriate section of 'add_variables.sh' script and .gitignore if needed to exclude secret data from git.

When you need it and what files:
* prometheus.yml - because you always need to add some additional hosts in case of production.
* alertmanager/config.yml - because you always need to add some additional recipients for alerts.
* docker-compose.yml - because better to split data per environment among prometheus daemons in case of storage retention, test cases and so on
* customize standard alerting rules - because sometime yous need to change some alerting rules, for example you should copy needed file:
~~~~
cp prometheus-prod/configs/alert_rules.d/la.yml prometheus-prod/configs/alert_rules.d/la_custom.yml
# add include for 'la_custom.yml' to 'prometheus.yml'
editor prometheus-prod/configs/prometheus.yml
~~~~

* other cases are rare

# Setup with selfsigned ssl

~~~~
cp -a docker-compose.yml.example docker-compose.yml.custom
# comment 'artiloop/nginx' and uncomment 'nginx' image for nginx container, comment current conf.d mount and uncomment alternative mount
# replace 'docker-compose.yml.example' by 'docker-compose.yml.custom' in file 'add_variables.sh'
editor add_variables.sh
source ./secrets
mkdir -p nginx/ssl/alertmanager.${REMOTE_HOST}/
mkdir -p nginx/ssl/grafana.${REMOTE_HOST}/
mkdir -p nginx/ssl/prometheus.${REMOTE_HOST}/
openssl req -x509 -newkey rsa:4096 -keyout private.key -out fullchain.pem -nodes -days 99999
cp private.key fullchain.pem nginx/ssl/alertmanager.${REMOTE_HOST}/
cp private.key fullchain.pem nginx/ssl/grafana.${REMOTE_HOST}/
cp private.key fullchain.pem nginx/ssl/prometheus.${REMOTE_HOST}/
rm private.key fullchain.pem
~~~~

# Setup kubernetes monitoring

See 'kubernetes example' in 'add_variables.sh.example'

# Info

## Our public repo with usefull code

https://github.com/shalb-docker?tab=repositories

# Useful commands

## Services management

### reload prometheus

~~~~
bash prometheus_reload.sh
~~~~

# Get binary exporters from docker containers images if no in repository

~~~~
# Example composer config to get containers:
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

# Run my_container a least once, find container_id via: docker ps -a | grep my_container
# Create containers (do Ctrl+C after creation):
exporter="postgres-exporter"
docker-compose up ${exporter}

# Find needed container:
container_id=$(docker ps -a | grep ${exporter} | awk '{print $1}')

# Copy file from container
rm -rf my_container
mkdir my_container && cd my_container
docker cp ${container_id}:/ ./

# Find needed binary in ./, copy it to playbook or to needed host
~~~~
