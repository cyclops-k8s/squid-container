#!/bin/bash

set -euo pipefail

if [ ! -d /squid-state/ssl_db ]
then
  echo "SSL certificate database directory not found. Creating..."
  /usr/lib/squid/security_file_certgen -c -s /squid-state/ssl_db -M 4MB
fi

echo "Removing old squid PID file if it exists..."
if [ -f /run/squid.pid ]
then
  rm -f /run/squid.pid
fi

if ! squid -zN
then
  echo "Error: squid cache directory initialization failed." >&2
  exit 1
fi

squid -zN

if ! squid -k parse
then
  echo "Error: squid configuration parse failed." >&2
  exit 1
fi

exec squid -NYCd 1 -f /etc/squid/squid.conf
