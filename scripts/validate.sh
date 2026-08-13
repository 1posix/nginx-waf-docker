#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

command -v docker >/dev/null 2>&1 || { echo "docker is required" >&2; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "docker compose plugin is required" >&2; exit 1; }

docker compose config >/dev/null
echo "[OK] compose.yaml"

docker compose build waf

echo "[OK] image build"

docker compose run --rm --no-deps waf nginx -t
echo "[OK] nginx + ModSecurity + CRS configuration"
