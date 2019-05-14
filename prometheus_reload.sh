kill -s SIGHUP $(ps aux | grep -v grep | grep '/bin/prometheus --log.level=debug' | awk '{print $2}')
