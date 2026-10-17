#!/bin/bash
set -e

DB_HOST="localhost"
DB_PORT="5432"

echo "=== INICIANDO AUTODIAGNÓSTICO SOAR-LITE ==="

# 1. Conexión a la Base de Datos
if ! command -v nc &> /dev/null; then
    echo "[FAIL] 'nc' no está instalado. No se puede verificar la conexión a la BD."
    exit 1
fi
if nc -z -v -w5 $DB_HOST $DB_PORT 2>&1; then
    echo "[OK] Conexión a Base de Datos de Métricas: EXITOSA"
else
    echo "[FAIL] Falla de conexión a la Base de Datos"
    exit 1
fi

# 2. Verificación de servicio Caddy WAF
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || true)
if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 403 ]; then
    echo "[OK] Servicio Web / WAF respondiendo adecuadamente (Status: $HTTP_STATUS)"
else
    echo "[WARN] Código HTTP inesperado: $HTTP_STATUS"
fi

# 3. Verificación de HTTPS (:443)
HTTPS_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" https://localhost/ || true)
if [ "$HTTPS_STATUS" -eq 200 ] || [ "$HTTPS_STATUS" -eq 403 ]; then
    echo "[OK] Servicio HTTPS respondiendo adecuadamente (Status: $HTTPS_STATUS)"
else
    echo "[WARN] HTTPS no disponible o código inesperado: $HTTPS_STATUS"
fi

echo "=== DIAGNÓSTICO FINALIZADO ==="
