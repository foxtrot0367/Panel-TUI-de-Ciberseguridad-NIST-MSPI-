cat > /opt/ciberseguridad_tui/caddy_alerts.sh << 'SCRIPT'
#!/bin/bash
CADDY_LOG="/var/log/caddy/access.log"
ALERT_LOG="/var/log/caddy_alerts.log"
BLOCKED_IPS="/var/log/cblocked_ips.log"
THRESHOLD=5

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_alert() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$ALERT_LOG"
}

tail -Fn0 "$CADDY_LOG" 2>/dev/null | while read -r line; do
    ip=$(echo "$line" | grep -oP '"ip":"[^"]*"' | cut -d'"' -f4)
    status=$(echo "$line" | grep -oP '"status":\d+' | grep -oP '\d+$')
    [ -z "$ip" ] && continue
    
    case "$status" in
        400) log_alert "CRITICO" "Payload malicioso desde $ip"; echo -e "${RED}[ALERTA] CRITICO: $ip${NC}" ;;
        403) log_alert "ALTA" "Acceso denegado (WAF) desde $ip" ;;
        405) log_alert "ALTA" "Método HTTP no permitido desde $ip" ;;
    esac
    
    fails=$(grep -c "\"ip\":\"$ip\"" "$ALERT_LOG" 2>/dev/null || echo "0")
    if [ "$fails" -ge "$THRESHOLD" ] && ! grep -q "Bloqueada: $ip" "$BLOCKED_IPS" 2>/dev/null; then
        sudo iptables -I INPUT -s "$ip" -j DROP
        echo "$(date) - Bloqueada: $ip" >> "$BLOCKED_IPS"
        log_alert "CRITICO" "IP $ip bloqueada ($THRESHOLD intentos)"
        echo -e "${RED}[BLOQUEO] $ip bloqueada${NC}"
        (sleep 3600 && sudo iptables -D INPUT -s "$ip" -j DROP) &
    fi
done
SCRIPT