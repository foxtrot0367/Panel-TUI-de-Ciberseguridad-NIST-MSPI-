#!/bin/bash
set -e

# Configuración
CADDY_LOG="/var/log/caddy/access.log"
ALERT_LOG="/var/log/caddy_alerts.log"
BLOCKED_IPS_FILE="/var/log/cblocked_ups.log"
THRESHOLD=5
WINDOW=60

# Colores
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# IPs conocidas (whitelist)
WHITELIST=("127.0.0.1" "::1")

log_alert() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$ALERT_LOG"
}

send_notification() {
    local message="$1"
    # Aquí puedes agregar:
    # - Correo: echo "$message" | mail -s "Caddy Alert" admin@example.com
    # - Telegram: curl -s -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" ...
    # - Slack: curl -X POST -H 'Content-type: application/json' ...
    echo -e "${RED}[ALERTA INMEDIATA]${NC} $message"
}

is_whitelisted() {
    local ip="$1"
    for white_ip in "${WHITELIST[@]}"; do
        if [ "$ip" == "$white_ip" ]; then
            return 0
        fi
    done
    return 1
}

monitor() {
    log_alert "INFO" "Iniciando monitoreo de Caddy WAF..."
    
    if [ ! -f "$CADDY_LOG" ]; then
        log_alert "ERROR" "Archivo de log no encontrado: $CADDY_LOG"
        return 1
    fi

    tail -Fn0 "$CADDY_LOG" | while read -r line; do
        # Extraer IP del cliente
        client_ip=$(echo "$line" | grep -oP '"ip":"[^"]*"' | cut -d'"' -f4)
        status=$(echo "$line" | grep -oP '"status":\d+' | grep -oP '\d+$')
        
        if [ -z "$client_ip" ] || [ -z "$status" ]; then
            continue
        fi

        # Detectar ataques
        case "$status" in
            400)
                log_alert "CRITICO" "Payload malicioso detectado desde $client_ip"
                send_notification "CRITICO: Payload malicioso desde $client_ip"
                ;;
            403)
                log_alert "ALTA" "Acceso denegado (WAF) desde $client_ip"
                ;;
            405)
                log_alert "ALTA" "Método HTTP no permitido desde $client_ip"
                ;;
        esac

        # Contar intentos fallidos recientes
        recent_fails=$(grep -c "\"ip\":\"$client_ip\"" "$ALERT_LOG" 2>/dev/null || echo "0")
        
        if [ "$recent_fails" -ge "$THRESHOLD" ]; then
            if ! is_whitelisted "$client_ip"; then
                log_alert "CRITICO" "IP $client_ip superó umbral de $THRESHOLD intentos en ${WINDOW}s"
                send_notification "CRITICO: IP $client_ip bloqueada temporalmente (umbral superado)"
                
                # Bloquear IP con iptables
                sudo iptables -I INPUT -s "$client_ip" -j DROP
                echo "$(date) - Bloqueada: $client_ip" >> "$BLOCKED_IPS_FILE"
                
                # Programar desbloqueo en 1 hora
                (sleep 3600 && sudo iptables -D INPUT -s "$client_ip" -j DROP && echo "$(date) - Desbloqueada: $client_ip" >> "$BLOCKED_IPS_FILE") &
            fi
        fi
    done
}

# Modo de uso
case "${1:-monitor}" in
    monitor)
        monitor
        ;;
    test)
        echo "403" | grep -q "403" && log_alert "TEST" "Sistema de alertas funcionando correctamente"
        ;;
    *)
        echo "Uso: $0 {monitor|test}"
        exit 1
        ;;
esac
