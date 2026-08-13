#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

docker compose exec waf nginx -t
docker compose exec waf nginx -s reload

echo "Nginx reloaded after successful validation."
