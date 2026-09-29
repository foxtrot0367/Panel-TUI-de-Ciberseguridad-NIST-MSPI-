#!/bin/bash
set -e

DB_HOST="localhost"
DB_PORT="5432"

echo "=== INICIANDO AUTODIAGNÓSTICO SOAR-LITE ==="

# 1. Conexión a la Base de Datos
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

echo "=== DIAGNÓSTICO FINALIZADO ==="
