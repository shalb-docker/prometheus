#!/bin/bash
env="$1"
if [ "$env" == "" ]
    then env="prod"
fi
echo "reloading ${env}"
docker-compose exec prometheus-${env} kill -s SIGHUP 1
