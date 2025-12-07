#!/bin/bash

BASE_DIR="$(pwd)"
NGINX_CONF="$BASE_DIR/config/nginx.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[INIT] Vérification de la structure WAF...${NC}"


if [ ! -f "$NGINX_CONF" ]; then
    echo -e "${RED}[ERREUR] Fichier manquant : config/nginx.conf${NC}"
    echo -e "${YELLOW}Pour éviter que Docker ne plante (conflit dossier/fichier), tu dois créer ce fichier.${NC}"
    echo "Action :"
    echo "  cp config/nginx.conf.exemple config/nginx.conf"
    exit 1
fi


DIRS=(
    "$BASE_DIR/logs"
    "$BASE_DIR/config/owasp-crs/rules"
)

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${GREEN}[+] Dossier créé : $dir${NC}"
    fi
done



FILES=(
    "$BASE_DIR/config/owasp-crs/crs-setup.conf"
)

for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        touch "$file"
        echo -e "${GREEN}[+] Fichier vide initialisé : $file${NC}"
    fi
done

chown -R $USER:$USER "$BASE_DIR"
chmod 755 "$BASE_DIR/"

echo -e "${GREEN}[OK] Structure locale validée.${NC}"
