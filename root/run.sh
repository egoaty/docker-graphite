#!/bin/bash
##
## Run the daemons (carbon, graphite)
##
## Environment Variables:
##  PUID ... unprivileged UID
##  PGID ... unprivileged GID
##
set -eu -o pipefail

user="graphite"
group="graphite"

if ! id ${user} >/dev/null 2>&1; then
        groupadd -g "${PGID:=100000}" "${group}"
        useradd -d / -M -g "${group}" -u "${PUID:=100000}" "${user}"
fi

chown -R ${user}:${group} /var/log
chown -R ${user}:${group} /opt/graphite/storage

runasuser="su - ${user} -c"

## Create database
[ -f "/opt/graphite/storage/graphite.db" ] || $runasuser "python3 /opt/graphite/webapp/manage.py migrate"

# Run gunicorn
$runasuser "PYTHONPATH=/opt/graphite/webapp gunicorn wsgi --workers=2 --threads=2 --bind=127.0.0.1:8080 --preload --pythonpath=/opt/graphite/webapp/graphite" &


# Run httpd
nginx -g 'daemon off;' &

# Run carbon daemon in background
$runasuser "/usr/bin/python3 /opt/graphite/bin/carbon-cache.py --debug start" &

set +e

_IN_TRAP=0
# Wait for termination or any child proccess exits then stop all others and quit
trap '
	_term_sig=$?;
	if [ ${_IN_TRAP} -eq 0 ]; then
		trap - EXIT SIGTERM SIGCHLD SIGINT;
		echo "Signal ${_term_sig} $( kill -l ${_term_sig} ) received. Killing jobs (TERM)!";
		kill $( jobs -p );
		wait;
		exit;
	fi
     ' EXIT SIGINT SIGTERM SIGCHLD


# Forward other signals
trap '
	_fwd_sig=$?;
	_IN_TRAP=1;
	if [ ${_fwd_sig} -gt 0 ]; then
		echo "Forwarding signal $( kill -l ${_fwd_sig} )!";
		kill -${_fwd_sig} $( jobs -p );
	fi
	_IN_TRAP=0;
     ' SIGHUP SIGQUIT SIGPIPE SIGALRM SIGUSR1 SIGUSR2 SIGTSTP SIGCONT SIGTTIN SIGTTOU SIGVTALRM SIGPROF

# Keep the script running
while true; do
	wait
done

