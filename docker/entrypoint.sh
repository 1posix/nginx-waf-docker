#!/usr/bin/env sh
set -eu

mkdir -p   /tmp/nginx/client_temp   /tmp/nginx/proxy_temp   /tmp/nginx/fastcgi_temp   /tmp/nginx/uwsgi_temp   /tmp/nginx/scgi_temp

if [ ! -w /var/log/modsecurity ]; then
  echo >&2 "ERROR: /var/log/modsecurity is not writable by container UID $(id -u)."
  echo >&2 "Run ./scripts/setup.sh on the host, then start the container again."
  exit 1
fi

if [ "$#" -gt 0 ] && [ "$1" = "nginx" ]; then
  nginx -t
fi

exec "$@"
