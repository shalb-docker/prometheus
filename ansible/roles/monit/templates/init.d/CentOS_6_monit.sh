#!/bin/bash
#
# Init file for Monit system monitor
# Written by Stewart Adam <s.adam@diffingo.com>
# based on script by Dag Wieers <dag@wieers.com>.
#
# chkconfig: - 98 02
# description: Utility for monitoring services on a Unix system
#
# processname: monit
# config: /etc/monitrc
# pidfile: /run/.monit.pid
# Short-Description: Monit is a system monitor

# {{ ansible_managed }}

monit_bin="{{ monit_exec_file_path }}"

start() {
    $monit_bin
}

stop() {
    if [ -f "/run/.monit.pid" ]
      then
        monit_pid=$(cat /run/.monit.pid)
      else
	    echo "/run/.monit.pid not exist"
	    killall $monit_bin
    fi
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

