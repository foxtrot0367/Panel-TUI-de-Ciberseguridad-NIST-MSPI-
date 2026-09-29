#!/bin/bash
set -e

BACKUP_DIR="/var/backups/soar_lite"
DATE=$(date +'%Y%m%d_%H%M%S')
DEST_FILE="$BACKUP_DIR/backup_soar_$DATE.tar.gz"
RETENTION_DAYS=7
TARGETS="/etc/caddy /etc/fail2ban /var/log/caddy"

mkdir -p "$BACKUP_DIR"
echo "[+] Iniciando copia de seguridad: $DATE"

tar -czf "$DEST_FILE" $TARGETS 2>/dev/null

if [ -f "$DEST_FILE" ]; then
    sha256sum "$DEST_FILE" > "$DEST_FILE.sha256"
    echo "[OK] Respaldo generado con hash de integridad."
else
    echo "[ERROR] Fallo al crear el respaldo."
    exit 1
fi

echo "[+] Limpiando respaldos con más de $RETENTION_DAYS días..."
find "$BACKUP_DIR" -type f -name "backup_soar_*.tar.gz*" -mtime +$RETENTION_DAYS -exec rm -f {} \;
echo "[✓] Proceso de respaldo finalizado."