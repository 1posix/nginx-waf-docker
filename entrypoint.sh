#!/bin/bash
set -e

OWASP_DIR="/etc/nginx/owasp-crs"
OWASP_BACKUP="/opt/owasp-crs-original"
MODSEC_BACKUP="/opt/modsec-backup"

copy_if_missing() {
    [ ! -e "$2" ] && cp -r "$1" "$2" 2>/dev/null
}

[ ! -d "$OWASP_BACKUP" ] && echo "[ERREUR] Backup OWASP introuvable" && exit 1

for item in "$OWASP_BACKUP"/*; do
    basename_item=$(basename "$item")
    [[ "$basename_item" != "rules" && "$basename_item" != "crs-setup.conf" ]] &&
        copy_if_missing "$item" "$OWASP_DIR/$basename_item"
done

if [ ! -d "$OWASP_DIR/rules" ] || [ -z "$(ls -A "$OWASP_DIR/rules" 2>/dev/null)" ]; then
    echo "[INIT] Copie des règles OWASP CRS..."
    mkdir -p "$OWASP_DIR/rules"
    cp -r "$OWASP_BACKUP/rules/"* "$OWASP_DIR/rules/"
fi

[ ! -s "$OWASP_DIR/crs-setup.conf" ] &&
    cp "$OWASP_BACKUP/crs-setup.conf" "$OWASP_DIR/crs-setup.conf"

[ ! -s "/etc/nginx/modsec/modsecurity.conf" ] &&
    cp "$MODSEC_BACKUP/modsecurity.conf" "/etc/nginx/modsec/modsecurity.conf"

chown -R nginx:nginx "$OWASP_DIR" 2>/dev/null
chmod -R 755 "$OWASP_DIR" 2>/dev/null

exec "$@"
