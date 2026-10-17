#!/bin/bash
set -e

BACKUP_DIR="/var/backups/soar_lite"
DATE=$(date +'%Y%m%d_%H%M%S')
DEST_FILE="$BACKUP_DIR/backup_soar_$DATE.tar.gz"
RETENTION_DAYS=7
TARGETS=""
[ -d "/etc/caddy" ] && TARGETS="$TARGETS /etc/caddy"
[ -d "/etc/fail2ban" ] && TARGETS="$TARGETS /etc/fail2ban"
[ -d "/var/log/caddy" ] && TARGETS="$TARGETS /var/log/caddy"

if [ -z "$TARGETS" ]; then
    echo "[WARN] No hay directorios de Caddy/Fail2ban instalados. Respaldo omitido."
    exit 0
fi

mkdir -p "$BACKUP_DIR"
echo "[+] Iniciando copia de seguridad: $DATE"

tar -czf "$DEST_FILE" $TARGETS

if [ -f "$DEST_FILE" ]; then
    sha256sum "$DEST_FILE" > "$DEST_FILE.sha256"
    echo "[OK] Respaldo generado. Verificando integridad..."
    if (cd "$BACKUP_DIR" && sha256sum -c "$DEST_FILE.sha256"); then
        echo "[OK] Verificación de integridad exitosa."
    else
        echo "[ERROR] Fallo en la verificación de integridad del respaldo."
        exit 1
    fi
else
    echo "[ERROR] Fallo al crear el respaldo."
    exit 1
fi

echo "[+] Limpiando respaldos con más de $RETENTION_DAYS días..."
find "$BACKUP_DIR" -type f -name "backup_soar_*.tar.gz*" -mtime +$RETENTION_DAYS -exec rm -f {} \;
echo "[✓] Proceso de respaldo finalizado."
