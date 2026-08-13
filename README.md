# nginx-waf-docker V2

Stable, reproducible reverse-proxy WAF for Docker based on Nginx, ModSecurity v3 and OWASP Core Rule Set.

## Stable baseline

| Component | Version / pin |
|---|---|
| Debian | 13 (trixie) |
| Nginx | 1.30.4 stable / `017cf98dcce217946572a896f0992370475e189f` |
| ModSecurity | 3.0.16 / `7ea9fefbe0ba409d8733b4d682c8c4c059cd028d` |
| ModSecurity-nginx | 1.0.4 / `3f4b57df10ce43b1f1c722141f7621dc64838be8` |
| OWASP CRS | 4.25.1 LTS / `3b89d5a05322f448b4b74b9cadc5fb05ac6915ad` |
| ngx_http_geoip2_module | 3.4 / `cbaa35461c62a99d2577e6bae3273492502d8769` |

CRS 4.25.1 LTS requires libmodsecurity 3.0.16 or newer; this repository intentionally pins that compatible pair.

## Design goals

- no moving `master` branches in production builds
- OWASP CRS is immutable inside the image
- local exclusions are separate from upstream rules
- Nginx runs as an unprivileged UID on ports 8080/8443 inside the container
- root filesystem is read-only; Linux capabilities are dropped
- logs are explicit and bounded
- config reloads are validated before being applied
- GeoIP and trusted-proxy Real-IP processing are opt-in
- rollback is just an image/version rollback

## Quick start

Requirements: Docker Engine with the Compose v2 plugin.

```bash
cp .env.example .env
./scripts/setup.sh
docker compose build
docker compose up -d
./tests/smoke.sh
```

Or:

```bash
make setup
make validate
make up
make test
```

The default listener is host TCP/80 -> container TCP/8080. The default server returns `444` except for `/health`, `/nginx_status` (localhost only), and the WAF-protected `/waf-test` smoke endpoint.

## Add a reverse proxy

Copy an example:

```bash
cp examples/nginx/sites/reverse-proxy.conf    config/nginx/sites-enabled/10-app.conf
```

Edit `server_name` and `proxy_pass`, then:

```bash
make reload
```

Every server inherits ModSecurity + CRS unless a location explicitly disables it. Do not disable ModSecurity for a whole application merely to fix one false positive; use a targeted exclusion in `config/modsecurity/custom/`.

## Network model

```text
Internet / LAN
      |
      v
 host:80/443
      |
      v
+-----------------------+
| nginx-waf             |
| Nginx + ModSecurity   |
| OWASP CRS 4.25.1 LTS  |
+-----------+-----------+
            |
        backend network / routed LAN
            |
      +-----+-----+
      |           |
     App         Plex
```

The strongest design is to make backends unreachable from untrusted networks except through the WAF. Docker services can be attached to `waf-backend`; routed LAN/VM backends should be restricted by your firewall so only the WAF can reach their web ports.

## ModSecurity / CRS tuning

Default baseline:

- blocking enabled (`SecRuleEngine On`)
- CRS blocking paranoia level 1
- inbound anomaly threshold 5
- outbound anomaly threshold 4
- CRS reporting level 1
- request body limit 16 MiB in both Nginx and ModSecurity

For migration of a complicated application, detection-only mode can be used temporarily. See `docs/MIGRATION-V1-V2.md`.

## Logs

Nginx:

```bash
docker compose logs -f waf
```

ModSecurity audit log:

```text
logs/modsecurity/audit.log
```

A logrotate example is provided under `examples/logrotate/`.

## GeoIP

Disabled by default. See `docs/GEOIP.md`. Use official MaxMind GeoLite2 databases and keep credentials outside Git/the image.

## TLS

TLS is opt-in because certificate management varies by infrastructure. See `examples/nginx/sites/https-example.conf`, mount `./certs:/etc/nginx/certs:ro`, and publish host port 443 to container port 8443.

## Common commands

```bash
make status
make logs
make reload
make test
make backup
```

## Important upgrade rule

Do **not** persist `/opt/owasp-crs` on the host. It belongs to the image. Upgrading the image is how CRS is upgraded. Persist only your own `crs-setup.conf` and `custom/` rules.

## Repository layout

```text
config/nginx/            user Nginx configuration
config/modsecurity/      user ModSecurity/CRS configuration
config/modsecurity/custom local exclusions/rules only
data/geoip/              optional MaxMind databases
logs/modsecurity/        persistent audit log
examples/                disabled examples/templates
scripts/                 safe operational helpers
tests/                   smoke tests
```

See `docs/OPERATIONS.md` for day-to-day operation and `docs/MIGRATION-V1-V2.md` before replacing a V1 deployment.
