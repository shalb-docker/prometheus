### Role Name

Role for monit client installation with base template and templates for many generic services and check scripts

### Requirements

#### nearly all services checks (need atop, bash)
apt-get install atop bash

#### apache (need status page, python3, bs4 module)

add config:
~~~~
<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Deny from all
    Allow from 127.0.0.1 ::1
</Location>
~~~~

install python3:
~~~~
apt-get install python3
ln -s /usr/bin/python3.x /usr/bin/python3
~~~~

install bs4 module:
~~~~
pip3 install --user bs4
~~~~

#### nginx check (need status page)

check if compilled with status module
~~~~
nginx -V |& grep -o with-http_stub_status_module
~~~~

add nginx config file:
~~~~
server {
    listen 80;
    server_name localhost 127.0.0.1;

    location /nginx_status {
        stub_status on;
        access_log   off;
        allow 127.0.0.1;
        deny all;
    }
}
~~~~

#### php-fpm check (need status page)

add in php-fpm config:
~~~~
pm.status_path = /fpm_status
~~~~
add nginx config file (add location to nginx status virtual host):
~~~~
    location /fpm_status {
        access_log off;
        allow 127.0.0.1;
        deny all;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass 127.0.0.1:9000;
       #fastcgi_pass unix:/var/run/php5-fpm.sock;
    }
~~~~

### Role Variables

#### Minimum configuration (no checks at all)

Run with tag 'basic' for minimal install.
Also watch defaults/main.yml which have comments for tags.

#### Minimal + basic system checks configuration

In group_vars/all/all.yml or further in ansible hierarchy you need to add variables:
~~~~
monit_alert_email:
  - "noreply@notexistant.nodomain"
~~~~

Run with tags 'basic' 'system_config' 'file_systems_config'

#### Maximum configuration (services monitoring, remote http, https, websocket hosts)

Per services variables examples for per group (group_vars/GROUPNAME/vars.yml) or per host (host_vars/HOSTNAME/vars.yml):

~~~~
services: # variable whish contain dictionary with services
  mysql: # dictionary for service mysql
    name: 'mysql' # dictionary key, which will be used for appropriate templates/monit.d/mysql.conf.j2 template and as result - config in /etc/monit.d/mysql.conf by default
    action: 'alert' # type of action for monit check - in this case, just alert action
   #action: 'exec "/etc/init.d/mysql restart"' # type of action for monit check - in this case, will restart mysql
	regexp: '/usr/sbin/mysqld' # regular expression for service detection in monit (test monit regex with command: monit procmatch "regex-pattern")
    port: '3306' # port, which will be uset by mysql checks
    repeat_interval: 180 # number of cycles - in our case cycle is number of seconds in variable "monit_service_check_interval", watch default in in defaults/main.yml
   #replication: "yes" # if replication status monitoring needed (seconds behind master) - uncomment if needed
  php-fpm:
    name: 'php-fpm'
    action: 'alert'
    action: 'exec "/etc/init.d/redis restart"'
	regexp: 'php-fpm: master process \(/etc/php/7.0/fpm/php-fpm.conf\)'
    port: '9000'
	virtual_host: 'nonexistant.none' # host name which will be checked on localhost
	virtual_host_action: 'alert' # action if virtual_host is not available
   #socket: '/var/run/php5-fpm_www.red.ua.sock' # if listen socket
    slow_log: '/var/log/php-fpm-www.log.slow'
	config_file: '/etc/php5/fpm/php-fpm.conf' # config file with number of childrens option (grep -r "^pm.max_children /etc/php*)
    repeat_interval: 60
  php-fpm2:
    name: 'php-fpm2'
    action: 'alert'
    regexp: 'php-fpm: master process \(/etc/php/fpm2-php5.3/php-fpm.conf\)'
    port: '9003'
   #socket: '/var/run/php5-fpm_www.red.ua.sock' # if listen socket
    slow_log: '/var/log/php-fpm2-www.log.slow'
    config_file: '/etc/php/fpm2-php5.3/php-fpm.conf' # config file with number of childrens option (grep -r "^pm.max_children /etc/php*)
    repeat_interval: 60
  redis:
    name: 'redis'
    action: 'exec "/etc/init.d/redis restart"'
	regexp: '/usr/sbin/redis-server 127.0.0.1:6379'
    port: '6379'
    repeat_interval: 60
  jenkins:
    name: 'jenkins'
    action: 'alert'
	regexp: 'regexp for monit'
    port: '8080'
    repeat_interval: 60
  nginx:
    name: 'nginx'
    action: 'exec "/etc/init.d/nginx restart"'
	regexp: 'nginx: master process /usr/sbin/nginx'
    port: '80'
    repeat_interval: 60
  memcached:
    name: 'memcached'
    action: 'exec "/usr/bin/systemctl restart memcached.service"'
	regexp: '/usr/bin/memcached -p 11211'
    port: '11211'
    repeat_interval: 60
  proftpd:
    name: 'proftpd'
    action: 'alert'
	regexp: 'regexp for monit'
    port: '21'
    repeat_interval: 60
  apache:
    name: 'apache'
    action: 'alert'
	regexp: 'regexp for monit'
    port: '80'
	virtual_host: 'nonexistant.none' # host name which will be checked on localhost
	virtual_host_action: 'alert' # action if virtual_host is not available
    repeat_interval: 60
  mmonit:
    name: 'mmonit'
    action: 'alert'
   #action: 'exec "/bin/systemctl restart mmonit"'
    regexp: '/opt/mmonit/bin/mmonit -i'
    port: '8081'
    repeat_interval: 60
  cachelog:
    name: 'cachelog'
    action: 'alert'
    regexp: '/usr/bin/php /var/www/prod/htdocs/exec/cron/cachelog.php'
    repeat_interval: 60
  keepalived:
    name: 'keepalived'
    action: 'alert'
	regexp: 'regexp for monit'
    repeat_interval: 60
  lsyncd:
    name: 'lsyncd'
    action: 'alert'
    regexp: '/usr/bin/lsyncd'
    repeat_interval: 60
  rundeck:
    name: 'rundeck'
    action: 'exec "/etc/init.d/rundeckd restart"'
	regexp: '-Drundeck.server.serverDir=/var/lib/rundeck'
	port: "4443"
    repeat_interval: 60
  rabbitmq:
    name: 'rabbitmq'
    action: 'exec "/etc/init.d/rabbitmq restart"'
    regexp: '/usr/lib64/erlang/erts-7.3/bin/beam -W w -A 512 -P 1048576 -K true -- -root /usr/lib64/erlang -progname erl -- -home /var/lib/rabbitmq -- -pa /usr/lib64/erlang/lib/rabbitmq_server-3.6.2/ebin'
    port: '25672'
    repeat_interval: 60
  haproxy:
    name: 'haproxy'
    action: 'exec "/etc/init.d/haproxy restart"'
    regexp: '/usr/bin/haproxy -D -p /run/haproxy.pid -f /etc/haproxy/haproxy.cfg'
    port: '3306'
    repeat_interval: 60
  mongodb:
    name: 'mongodb'
    action: 'exec "/etc/init.d/mongodb restart"'
    regexp: '/usr/bin/mongod --config /etc/mongodb.conf'
    port: '27017'
    repeat_interval: 60
  sphinx:
    name: 'sphinx'
    action: 'exec "/etc/init.d/searchd restart"'
    regexp: '/usr/local/bin/searchd'
    port: '9312'
    repeat_interval: 60
  sphinx2:
    name: 'sphinx2'
    action: 'exec "/etc/init.d/searchd_rt restart"'
    regexp: 'searchd_rt -c /usr/local/etc/sphinx_rt.conf'
    port: '9306'
    repeat_interval: 60
  sitekit-engine:
    name: 'sitekit-engine'
    action: 'alert'
    regexp: 'python /cools/sitekit-engine/app.py'
    port: '50900'
    repeat_interval: 60
  docker:
    name: 'docker'
    action: 'exec "/etc/init.d/docker restart"'
    regexp: '/usr/bin/docker daemon'
    repeat_interval: 60
  postfix:
    name: 'postfix'
    action: 'exec "/bin/systemctl restart postfix.service"'
    regexp: '/usr/lib/postfix/sbin/master'
    port: '25'
    repeat_interval: 60
  cron:
    name: 'cron'
    action: 'exec "/bin/systemctl restart cron.service"'
    regexp: '/usr/sbin/cron -f'
    repeat_interval: 60
  ntpd:
    name: 'ntpd'
    action: 'exec "/bin/systemctl restart ntp.service"'
    regexp: '/usr/sbin/ntpd'
    repeat_interval: 60
  nrpe:
    name: 'nrpe'
    action: 'exec "/usr/bin/systemctl restart nagios-nrpe-server.service"'
    regexp: '/usr/sbin/nrpe'
	port: '5666'
    repeat_interval: 60
  snmpd:
    name: 'snmpd'
    action: 'exec "/usr/bin/systemctl restart snmpd.service"'
    regexp: '/usr/sbin/snmpd'
    repeat_interval: 60
  redmine:
    name: 'redmine'
    action: 'exec "/bin/systemctl restart redmine.service"'
    regexp: 'redmine'
    repeat_interval: 60
  fail2ban:
    name: 'fail2ban'
    action: 'alert'
   #action: 'exec "/bin/systemctl restart fail2ban.service"'
    regexp: '/usr/bin/fail2ban-server'
    repeat_interval: 60
  ssh:
    name: 'ssh'
    action: 'alert'
   #action: 'exec "/bin/systemctl restart ssh.service"'
    regexp: '/usr/sbin/sshd'
    port: '22'
    repeat_interval: 60
  supervisor:
    name: 'supervisor'
    action: 'alert'
   #action: 'exec "/bin/systemctl restart supervisor.service"'
    regexp: '/usr/bin/supervisord'
    repeat_interval: 60
  sendmail:
    name: 'sendmail'
    action: 'alert'
   #action: 'exec "/usr/bin/service sendmail restart"'
    regexp: 'sendmail: MTA:'
    port: '25'
    repeat_interval: 60
  opendkim:
    name: 'opendkim'
    action: 'exec "/etc/init.d/opendkim status"'
    regexp: '/usr/sbin/opendkim'
    port: '8891'
    repeat_interval: 60
  snmpd:
    name: 'snmpd'
    action: 'exec "/etc/init.d/snmpd status"'
    regexp: '/usr/sbin/snmpd'
    port: '161'
    repeat_interval: 60
  supervisord:
    name: 'supervisord'
    action: 'exec "/etc/init.d/supervisord status"'
    regexp: '/usr/lib/python-exec/python2.7/supervisord'
    repeat_interval: 60
  filebeat:
    name: 'filebeat'
    action: 'exec "/etc/init.d/filebeat status"'
    regexp: '/usr/bin/filebeat'
    repeat_interval: 60
  memcached:
    name: 'memcached'
    action: 'exec "/etc/init.d/memcached status"'
    regexp: '/usr/bin/memcached -d -p 11211'
    repeat_interval: 60
  xinetd:
    name: 'xinetd'
    action: 'exec "/etc/init.d/xinetd status"'
    regexp: '/usr/sbin/xinetd'
    repeat_interval: 60
  sysklogd:
    name: 'sysklogd'
    action: 'exec "/etc/init.d/sysklogd status"'
    regexp: '/usr/sbin/syslogd'
    repeat_interval: 60
~~~~

Remote hosts checks examples:

~~~~
remote_hosts_to_check:
  ssh:
    - name:    'first-example'
      address: 'first-example.com'
      host:    'first-example.com'
      port:    '22'
  https:
    - name:    'first-example'
      address: 'first-example.com'
      host:    'first-example.com'
      port:    '443'
      request: '/'
    - name:    'second-example'
      address: '93.150.1.27'
      host:    'second-example.com'
      port:    '8080'
      request: '/my_request'
  http:
    - name:    'first-example'
      address: 'first-example.com'
      host:    'first-example.com'
      port:    '80'
      request: '/'
  websocket:
    - name:    'first-example'
      address: 'first.example.com'
      host:    'first.example.com'
      port:    '80'
      request: '/'
      origin:  'http://example.com'
~~~~

Mounts checks examples:

~~~~
mounts:
  local:
    - name: 'root'
      mount_point: '/'
      alert_percent: 80
      action: 'alert'
    - name: 'data'
      mount_point: '/data'
      alert_percent: 80
      action: 'alert'
  remote:
    - name: 'pricer'
      mount_point: '/server/htdocs/pricer'
      action: 'alert'
    - name: 'tx'
      mount_point: '/server/htdocs/prod/img/tx'
      action: 'alert'
~~~~

Network interfaces checks examples:

~~~~
network_interfaces:
  hardware:
    - name: 'public'
      device: 'enp5s0'
      ipv4: '77.222.150.19/28'
      action: 'alert'
~~~~

### Example Playbook

example playbook monit.yml:
~~~~
    - hosts: servers
      roles:
         - monit
~~~~

### Todo

~~~~
variables for 'username' and 'password'  - actual problem for shared hosting hosts
set mailserver localhost port 25 username "MY_USERNAME" password "MY_PASSWORD"

system.conf
CHECK SYSTEM $HOST
  IF MEMORY USAGE > 81% THEN EXEC "/usr/bin/systemctl restart php-fpm.service"

mounts.conf
CHECK FILESYSTEM mount_/dev/sda2_/ WITH PATH /
IF SPACE USAGE > 90% then alert
IF SPACE FREE < 4 GB then exec "/usr/bin/monit unmonitor mysql && /usr/bin/systemctl stop mysqld.service"

lsync_file.check
check process lsyncd
  with pidfile "/var/run/lsyncd.pid"
  start program = "/usr/bin/lsyncd /etc/lsyncd/lsyncd.conf.lua"
  stop program = "/usr/bin/killall lsyncd"
  if 3 restarts within 3 cycles then alert

CHECK PROGRAM lsync_file WITH PATH "/usr/bin/flock -xw 1 /tmp/lsync_file.lock -c '/usr/local/scripts/monit/lsync_file.sh example.com'" 
  IF STATUS != 0 FOR 1 CYCLES THEN ALERT
  depends on lsyncd
~~~~

### License
-------

BSD

### Author Information

shalb
