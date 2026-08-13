# Operations

## Safe configuration reload

```bash
make reload
```

This runs `nginx -t` first and only then sends a graceful reload signal.

## Logs

Nginx access/error logs are emitted to stdout/stderr and are rotated by Docker's `local` logging driver.

ModSecurity audit records are persisted in:

```text
logs/modsecurity/audit.log
```

Use the example logrotate policy in `examples/logrotate/nginx-waf` for host-side rotation.

## Health

```bash
make status
curl -fsS http://127.0.0.1/health
```

## Backup

```bash
make backup
```

Certificates and secrets are intentionally not included by the generic backup script.

## Upgrade policy

Do not edit the embedded CRS directory. Upgrade component versions in a branch, rebuild, run smoke tests, inspect false positives, then roll forward. Keep the previous image tag available for rollback.
