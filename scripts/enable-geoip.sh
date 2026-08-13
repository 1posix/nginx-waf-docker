#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DB="data/geoip/GeoLite2-Country.mmdb"
DEST="config/nginx/conf.d/35-geoip.conf"

if [[ ! -s "$DB" ]]; then
  echo "Missing $DB" >&2
  echo "Install/update GeoLite2 from MaxMind first; see docs/GEOIP.md." >&2
  exit 1
fi

cp examples/nginx/conf.d/35-geoip.conf "$DEST"
echo "Enabled GeoIP config at $DEST"
echo "Run ./scripts/reload.sh"
