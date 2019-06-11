#!/bin/sh

### BEGIN INIT INFO
# Provides:          monit
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Should-Start:      $all
# Should-Stop:       $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: service and resource monitoring daemon
# Description:       monit is a utility for managing and monitoring
#                    processes, programs, files, directories and filesystems
#                    on a Unix system. Monit conducts automatic maintenance
#                    and repair and can execute meaningful causal actions
#                    in error situations.
### END INIT INFO

# {{ ansible_managed }}

monit_bin="{{ monit_exec_file_path }}"
monit_pid=$(cat /run/.monit.pid)

start() {
    $monit_bin
}

stop() {
    if [ -f "/proc/${monit_pid}/comm" ]; then
        pid_comm=$(cat /proc/${monit_pid}/comm)
        if [ "$pid_comm" = "monit" ]; then
            kill -15 $monit_pid
        fi
    fi
    killall -s KILL {{ monit_exec_file_path }}
}

restart() {
    stop
    sleep 3
    start
}

reload() {
    $monit_bin -t && $monit_bin reload
}

status() {
    $monit_bin status
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
    reload)
        reload
        ;;
    status)
        status
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|reload}"
        exit 2
esac
exit $?

