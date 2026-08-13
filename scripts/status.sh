#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

docker compose ps
printf '
--- health ---
'
docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' nginx-waf 2>/dev/null || true
printf '
--- versions ---
'
docker compose exec waf nginx -v 2>&1 || true
