files="
        docker-compose.yml
        grafana/env
        nginx/conf.d/default.conf
        postfix-relay/main.cf
        prometheus-prod/configs/alert_rules.d/*.yml
        prometheus-prod2/configs/alert_rules.d/*.yml
        prometheus-dev/configs/alert_rules.d/*.yml
"

for f in $files
    do rm -f $f
done


