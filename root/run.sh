#!/bin/sh
##
## Run the daemons (carbon, graphite)
##
## Environment Variables:
##  PUID ... unprivileged UID
##  PGID ... unprivileged GID
##
set -euf -o pipefail

user="graphite"
group="graphite"
if ! id ${user} >/dev/null 2>&1; then 
	addgroup -g "${PGID:=100000}" "${group}"
	adduser -h / -H -D -G "${group}" -u "${PUID:=100000}" "${user}"
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
$runasuser "/opt/graphite/bin/carbon-cache.py --debug start" &

set +e

_IN_TRAP=0
# Wait for termination or any child proccess exits then stop all others and quit
trap '
	_term_sig=$(( $? - 128 ));
	if [ ${_IN_TRAP} -eq 0 ]; then
		trap - EXIT SIGTERM SIGCHLD;
		echo "signal $( kill -l ${_term_sig} ) received!";
		kill $( jobs -p );
		wait;
		exit;
	fi
     ' EXIT SIGTERM SIGCHLD


# Forward other signals
trap '
	_fwd_sig=$(( $? - 128 ));
	_IN_TRAP=1;
	if [ ${_fwd_sig} -gt 0 ]; then
		echo "forwarding signal $( kill -l ${_fwd_sig} )!";
		kill -${_fwd_sig} $( jobs -p );
	fi
	_IN_TRAP=0;
     ' SIGHUP SIGINT SIGQUIT SIGPIPE SIGALRM SIGUSR1 SIGUSR2 SIGTSTP SIGCONT SIGTTIN SIGTTOU SIGVTALRM SIGPROF

# Keep the script running
while true; do
	wait
done

