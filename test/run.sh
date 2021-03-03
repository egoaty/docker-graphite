#!/bin/bash
##
## Run the daemons (carbon, graphite)
##
## Environment Variables:
##  PUID ... unprivileged UID
##  PGID ... unprivileged GID
##
set -euf -o pipefail

function exitOnError() {
	echo test
}

#user="graphite"
#group="graphite"
#if ! id ${user} >/dev/null 2>&1; then 
#	addgroup -g "${PGID:=100000}" "${group}"
#	adduser -h / -H -D -G "${group}" -u "${PUID:=100000}" "${user}"
#fi
#
#chown -R ${user}:${group} /var/log
#chown -R ${user}:${group} /opt/graphite/storage

## Create database
#[ -f "/opt/graphite/storage/graphite.db" ] || python3 /opt/graphite/webapp/manage.py migrate


trap exitOnError SIGCHLD
set -m

echo a

sleep infinity
# Run gunicorn in backgroud
#PYTHONPATH=/opt/graphite/webapp gunicorn wsgi --workers=4 --bind=0.0.0.0:80 --preload --pythonpath=/opt/graphite/webapp/graphite &

# Run carbon daemon
#exec /opt/graphite/bin/carbon-cache.py --debug start

