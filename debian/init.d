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

set -e

# Variables:
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON="/usr/lib/libreoffice/program/soffice.bin"
DAEMON_HOST=
DAEMON_PORT=
TEMP_DIR='/tmp'
NAME='libreofficed'
DESC='LibreOffice Multiport Daemon'
LANG=C.UTF-8


# Exit if the package is not installed
test -x "$DAEMON"  || exit 0

# Read configuration variable file if it is present
[ -r "/etc/default/locale" ]  && . "/etc/default/locale"
[ -r "/etc/default/${NAME}" ] && . "/etc/default/${NAME}"

. /lib/lsb/init-functions

SRC_DIR=$(pwd)
DAEMON_NAME=$(basename ${DAEMON})
DAEMON_HOME=$(dirname ${DAEMON})
SCRIPTNAME="/etc/init.d/${NAME}"
TEMP_HOME="${TEMP_DIR}/${NAME}"

_create_home() {
    port=$1
    home=${TEMP_HOME}/port${port}
    mkdir -p ${home}
    echo ${home}
}

_test_ports() {
    echo $(ps axX -U "root" | grep "${DAEMON_HOME}" | grep "${DAEMON_NAME}" | awk '{print $11}' | sed 's/.*port=\([[:digit:]]*\)\;.*/\1/');
}

do_start() {

    PORTS=$(_test_ports);

    if [ "${PORTS}" ]; then

        echo -n "${NAME} is already running..."

        log_end_msg 1

        return 1

    fi;

    export LANG

    cd ${DAEMON_HOME}

    host=${DAEMON_HOST:-localhost}

    # All ports... default is standard port 2002
    for port in ${DAEMON_PORT:-2002}
    do
        # Set user home
        export HOME=$(_create_home ${port})

        sock="socket,host=${host},port=${port};tcpNoDelay=1;urp;StarOffice.Service"
        opts="--headless --invisible --nofirststartwizard --nodefault --nologo --norestore"

        nohup ${DAEMON} --accept="${sock}" ${opts} 1>"${HOME}.log" 2>&1 &

    done

    echo -n "listens on ${DAEMON_PORT:-2002} port(s)"
    log_end_msg 0

    cd ${SRC_DIR}

    return 0
}

do_stop() {

    PORTS=$(_test_ports);

    if [ "${PORTS}" ]
    then
        killall "${DAEMON_NAME}"
        [ ! ${1} ] && echo -n "done" && log_end_msg 0
        return 0
    fi

    [ ! ${1} ] && echo -n "${NAME} is not running" && log_end_msg 1

    return 1
}

do_status() {

    PORTS=$(_test_ports);

    if [ "${PORTS}" ]
    then
        echo -n "listens on ${PORTS} port(s)"
        log_end_msg 0
    else
        echo -n "${NAME} is not running"
        log_end_msg 1
    fi
}


case "$1" in
    start)
        log_begin_msg "Starting ${DESC}: "
        do_start
    ;;
    stop)
        log_begin_msg "Stopping ${DESC}: "
        do_stop
    ;;
    restart|reload|force-reload)
        log_begin_msg "Restarting ${DESC}: "
        do_stop 1 && sleep 1
        do_start
    ;;
    status)
        log_begin_msg "Status of ${DESC}: "
        do_status
    ;;
    *)
        echo "Usage: ${SCRIPTNAME} {start|stop|status|restart|reload|force-reload}" >&2
        exit 3
    ;;
esac

exit 0


