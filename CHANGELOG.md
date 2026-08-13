# Changelog

## 2.0.3 - 2026-08-13

### Fixed

- Initialize `tx.crs_setup_version=4251` for OWASP CRS 4.25.1.
- Fix WAF smoke tests to use a hostname instead of a numeric Host header.
- Remove unsupported/unneeded `SecDataDir` configuration for ModSecurity v3.
- Fix the WAF test endpoint newline.
- Align all project version references to 2.0.3.

## 2.0.0 - 2026-08-13

Initial V2 stable baseline.

- Debian 13 runtime/build base
- Nginx 1.30.4 stable exact release commit
- ModSecurity 3.0.16 exact release commit
- ModSecurity-nginx 1.0.4 exact release commit
- OWASP CRS 4.25.1 LTS exact release commit
- GeoIP2 module 3.4 exact release commit
- immutable CRS bundled in the image
- non-root runtime UID/GID 10001
- read-only root filesystem + all Linux capabilities dropped
- HTTP healthcheck
- JSON Nginx logs to stdout/stderr
- persistent ModSecurity audit log
- centralized rate-limit profiles with HTTP 429
- safe WebSocket header handling
- Real-IP and GeoIP disabled by default until explicitly trusted/configured
- safe reload, validation, backup and WAF smoke-test scripts
