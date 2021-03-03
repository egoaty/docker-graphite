#!/bin/sh

# Ping test
ping="$(echo PING | nc -w 10 localhost 3310)"
if [ "${ping}" != "PONG" ]; then
	echo "Error contacting ClamAV (${ping})"
	exit 1
fi

# Test for Frshclam process
if ! kill -0 $( cat /tmp/freshclam.pid ) >/dev/null 2>&1; then
	echo "Freshclam not running"
	exit 1
fi

# Test if database has been detected as outdated
if [ -f "/database/FRESHCLAM_OUTDATED" ]; then
	echo "ClamAV Database outdated"
	exit 1
fi

echo "OK"
