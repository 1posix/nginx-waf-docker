#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="backups/nginx-waf-config-${STAMP}.tar.gz"
mkdir -p backups

tar   --exclude='config/geoip/GeoIP.conf'   --exclude='certs/*'   -czf "$OUT"   compose.yaml .env.example VERSION config examples scripts

echo "$OUT"
