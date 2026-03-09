#!/bin/bash

set -e

echo "Generating TLS Cert cache directories..."
if [ ! -d /squid-state/ssl_db ]
then
    mkdir -p /squid-state/ssl_db || {
        echo "Error: Failed to create /squid-state/ssl_db" >&2
        exit 1
    }
fi

# Ensure the SSL cache directory is writable by the current user
if [ ! -w /squid-state/ssl_db ]
then
    # Try to adjust ownership to the current user if permissions allow
    if ! chown "$(id -u)":"$(id -g)" /squid-state/ssl_db
    then
        echo "Error: /squid-state/ssl_db is not writable and ownership cannot be changed." >&2
        exit 1
    fi
fi

/usr/lib/squid/security_file_certgen -c -s /squid-state/ssl_db -M 4MB

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