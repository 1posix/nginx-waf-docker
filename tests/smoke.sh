#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

set -a
[[ -f .env ]] && source .env
set +a

PORT="${HTTP_PORT:-80}"
BASE="${WAF_TEST_BASE:-http://127.0.0.1:${PORT}}"
HOST="${WAF_TEST_HOST:-waf.local}"

expect_code() {
  local name="$1" expected="$2" url="$3"
  local code
  code="$(curl -sS -H "Host: ${HOST}" -o /dev/null -w '%{http_code}' --max-time 5 "$url" || true)"
  if [[ "$code" != "$expected" ]]; then
    echo "[FAIL] $name: expected $expected, got $code" >&2
    return 1
  fi
  echo "[OK] $name -> $code"
}

expect_block() {
  local name="$1" url="$2"
  local code
  code="$(curl -sS -H "Host: ${HOST}" -o /dev/null -w '%{http_code}' --max-time 5 "$url" || true)"
  case "$code" in
    403|400) echo "[OK] $name blocked -> $code" ;;
    *) echo "[FAIL] $name was not blocked (HTTP $code)" >&2; return 1 ;;
  esac
}

expect_code "health" 200 "${BASE}/health"
expect_code "benign WAF endpoint" 200 "${BASE}/waf-test?name=alice"
expect_block "XSS" "${BASE}/waf-test?q=%3Cscript%3Ealert%281%29%3C%2Fscript%3E"
expect_block "SQL injection" "${BASE}/waf-test?id=1%27%20OR%20%271%27%3D%271"
expect_block "path traversal" "${BASE}/waf-test?file=..%2F..%2Fetc%2Fpasswd"

echo "Smoke tests passed."
