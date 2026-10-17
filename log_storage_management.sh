#!/bin/bash
set -e

LOG_SRC_DIR="/var/log/caddy"
LOG_ARCHIVE_DIR="/var/log/archives_soar"
RETENTION_DAYS=30
DATE_STAMP=$(date +'%Y%m%d_%H%M%S')

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[+] Gestionando almacenamiento de logs...${NC}"
mkdir -p "$LOG_ARCHIVE_DIR"

if [ -d "$LOG_SRC_DIR" ]; then
    find "$LOG_SRC_DIR" -type f \( -name "*.log" -size +10M -o -name "*.log.*" \) | while read -r log_file; do
        filename=$(basename "$log_file")
        archive_name="log_archive_${DATE_STAMP}_${filename}.gz"
        
        gzip -c "$log_file" > "$LOG_ARCHIVE_DIR/$archive_name"
        sha256sum "$LOG_ARCHIVE_DIR/$archive_name" > "$LOG_ARCHIVE_DIR/$archive_name.sha256"
        > "$log_file"
        echo -e "${GREEN}[OK] Log archivado: $archive_name${NC}"
    done
fi

echo -e "${GREEN}[+] Eliminando archivos comprimidos antiguos (+30 días)...${NC}"
find "$LOG_ARCHIVE_DIR" -type f \( -name "*.gz" -o -name "*.sha256" \) -mtime +$RETENTION_DAYS -exec rm -f {} \;

cat << 'EOF' | sudo tee /etc/logrotate.d/soar_caddy
/var/log/caddy/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        systemctl reload caddy > /dev/null 2>&1 || true
    endscript
}
EOF

echo -e "${GREEN}[✓] Almacenamiento de logs procesado con éxito.${NC}"
