#!/bin/bash

start() {
    /etc/local.d/monit.start
}

stop() {
    /etc/local.d/monit.stop
}

restart() {
    stop
    sleep 1
    start
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    *)
        echo $"Usage: $0 {start|stop|restart}"
        exit 2
esac
exit $?

