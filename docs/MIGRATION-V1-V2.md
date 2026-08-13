# Migration V1 -> V2

Do not replace a running V1 in-place without first preserving its configuration.

## 1. Back up V1

Save at minimum:

- Nginx virtual hosts / `conf.d`
- custom ModSecurity rules and exclusions
- CRS setup changes
- TLS certificates/keys
- GeoIP policy
- current container/image version

## 2. Do not copy the old `owasp-crs/rules` directory

V2 embeds OWASP CRS in the immutable image. Only migrate your local exclusions and custom rules into:

```text
config/modsecurity/custom/
```

Review rule IDs when migrating from an older CRS release.

## 3. Rebuild virtual hosts

Start from files in `examples/nginx/sites/`. Do not copy legacy proxy headers blindly, especially `Connection` / WebSocket handling and untrusted Real-IP settings.

## 4. First cutover

For a sensitive production service, consider temporarily changing:

```text
SecRuleEngine On
```

to:

```text
SecRuleEngine DetectionOnly
```

in `config/modsecurity/engine.conf`, exercise legitimate application workflows, inspect the audit log, add targeted exclusions, and restore `On` before final cutover.

## 5. Validate

```bash
make setup
make validate
make up
make test
```

Then add one application at a time and run `make reload` after each change.
