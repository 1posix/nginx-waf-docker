#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

mkdir -p   logs/modsecurity   data/geoip   certs   backups   config/nginx/sites-enabled

touch logs/.gitkeep logs/modsecurity/.gitkeep data/geoip/.gitkeep certs/.gitkeep backups/.gitkeep

UID_TARGET="${WAF_UID:-10001}"
GID_TARGET="${WAF_GID:-10001}"

if chown -R "${UID_TARGET}:${GID_TARGET}" logs/modsecurity 2>/dev/null; then
  chmod 0750 logs/modsecurity
else
  echo "WARNING: could not chown logs/modsecurity." >&2
  echo "Run as root: chown -R ${UID_TARGET}:${GID_TARGET} '$ROOT/logs/modsecurity'" >&2
fi

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  docker compose config >/dev/null
  echo "Compose configuration: OK"
fi

echo "Setup complete. Next: docker compose build && docker compose up -d"
