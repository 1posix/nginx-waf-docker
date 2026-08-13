# GeoIP (optional)

GeoIP is deliberately disabled by default so the WAF starts without third-party databases or credentials.

Use MaxMind's official GeoLite2 distribution. Put at least:

```text
data/geoip/GeoLite2-Country.mmdb
```

Then run:

```bash
./scripts/enable-geoip.sh
./scripts/reload.sh
```

For automatic database updates on Debian, use MaxMind `geoipupdate` on the host (or a dedicated sidecar) and point its database directory at this repository's `data/geoip/` directory. Do not bake MaxMind account/license credentials into the WAF image or commit them to Git.

The example GeoIP policy contains no blocked country by default. Geographic policy is local infrastructure policy and should remain explicit.
