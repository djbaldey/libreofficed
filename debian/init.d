#!/bin/sh
### BEGIN INIT INFO
# Provides:          libreofficed
# Required-Start:    $local_fs $remote_fs $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: LibreOffice Multiport Daemon
# Description:       Starts and stops multiple instances of libreoffice listeners.
### END INIT INFO

# Author: Grigoriy Kramarenko <root@rosix.ru>

# Variables:
DAEMON="/usr/lib/libreoffice/program/soffice.bin"
DAEMON_HOST=
DAEMON_PORT=
TEMP_DIR='/tmp'

NAME=`grep --max-count=1 "^# Provides:" $(readlink -f $0)|cut --delimiter=' ' --field=3-|sed 's/^ *//'`

# Read configuration variable file if it is present
[ -r "/etc/default/${NAME}" ] && . "/etc/default/${NAME}"

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Rewrite if it changed from config
NAME=`grep --max-count=1 "^# Provides:" $(readlink -f $0)|cut --delimiter=' ' --field=3-|sed 's/^ *//'`
DESC=`grep --max-count=1 "^# Short-Description:" $(readlink -f $0)|cut --delimiter=' ' --field=3-|sed 's/^ *//'`

SRC_DIR=`pwd`
DAEMON_NAME=`basename ${DAEMON}`
DAEMON_HOME=`dirname ${DAEMON}`
SCRIPTNAME="/etc/init.d/${NAME}"
TEMP_HOME="${TEMP_DIR}/${NAME}"

_create_home() {
    port=$1
    home=${TEMP_HOME}/port${port}
    mkdir -p ${home}
    echo ${home}
}

do_start() {
    cd ${DAEMON_HOME}

    host=${DAEMON_HOST:-localhost}

    # All ports... default is standard port 2002
    for port in ${DAEMON_PORT:-2002}
    do
        # Set user home
        HOME=$(_create_home ${port})
        export HOME

        # Start daemon
        echo "Run instance on ${host}:${port} using home directory ${HOME}"

        sock="socket,host=${host},port=${port};urp;StarOffice.ComponentContext"
        opts="--headless --invisible --nocrashreport --nodefault --nologo --nofirststartwizard --norestore"

        nohup ${DAEMON} --userid="port${port}" ${opts} --accept="${sock}" 1>"${HOME}.log" 2>&1 &
    done

    cd ${SRC_DIR}

    return 0
}

do_stop() {
    echo "killall '${DAEMON_NAME}'" && killall "${DAEMON_NAME}"
    return 0
}

do_status()
{
    ps axu | grep "root" | grep "${DAEMON_HOME}" | grep "${DAEMON_NAME}"
    return 0
}


case "$1" in
  start)
    echo "Starting ${DESC}"
    do_start
    ;;
  stop)
    echo "Stopping ${DESC}"
    do_stop
    ;;
  status)
    do_status
    ;;
  restart)
    do_stop && sleep 1 && do_start
    ;;
  force-reload)
    do_stop && sleep 1 && do_start
    ;;
  *)
    echo "Usage: ${SCRIPTNAME} {start|stop|status|restart|force-reload}" >&2
    exit 3
    ;;
esac

:
