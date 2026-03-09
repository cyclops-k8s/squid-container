#!/bin/bash

set -e

if [ ! -d /squid-state/ssl_db ]
then
    echo "SSL certificate database directory not found. Creating..."
    /usr/lib/squid/security_file_certgen -c -s /squid-state/ssl_db -M 4MB
fi

echo "Creating cache directories..."
rm -f /run/squid.pid

if ! squid -zN; then
    echo "Error: squid cache directory initialization failed." >&2
    exit 1
fi

squid -zN

while [ -f /run/squid.pid ]
do
    echo "Waiting for squid to create cache directories..."
    sleep 1
done

tail -F /var/log/squid/access.log &
TAIL_ACCESS_PID=$!

tail -F /var/log/squid/store.log &
TAIL_STORE_PID=$!

trap 'kill "$TAIL_ACCESS_PID" "$TAIL_STORE_PID" 2>/dev/null || true' TERM INT EXIT

exec squid -NYCd 1 -f /etc/squid/squid.conf