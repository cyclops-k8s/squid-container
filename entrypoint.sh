#!/bin/bash

echo "Generating TLS Cert cache directories..."
/usr/lib/squid/security_file_certgen -c -s /squid-state/ssl_db -M 4MB

echo "Creating cache directories..."
squid -zN

while [ -f /run/squid.pid ]
do
    echo "Waiting for squid to create cache directories..."
    sleep 1
done

tail -F /var/log/squid/access.log &
tail -F /var/log/squid/store.log &

squid -NYCd 1 -f /etc/squid/squid.conf