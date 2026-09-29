#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPORT_FILE="/var/log/network_audit_$(date +'%Y%m%d_%H%M%S').log"
echo -e "${BLUE}=== EVALUACIÓN Y AUDITORÍA DE RED ===${NC}" | tee -a "$REPORT_FILE"

# 1. Direccionamiento IP
echo -e "\n${GREEN}[1] INTERFACES Y DIRECCIONAMIENTO IP${NC}" | tee -a "$REPORT_FILE"
ip -br addr show | tee -a "$REPORT_FILE"

# 2. Puertos en escucha
echo -e "\n${GREEN}[2] PUERTOS TCP/UDP EN ESCUCHA${NC}" | tee -a "$REPORT_FILE"
if command -v ss &> /dev/null; then ss -tulpn | tee -a "$REPORT_FILE"; else netstat -tulpn | tee -a "$REPORT_FILE"; fi

# 3. Conexiones establecidas
echo -e "\n${GREEN}[3] CONEXIONES ESTABLECIDAS${NC}" | tee -a "$REPORT_FILE"
if command -v ss &> /dev/null; then ss -tun state established | tee -a "$REPORT_FILE"; else netstat -tun | grep ESTABLISHED | tee -a "$REPORT_FILE"; fi

# 4. Reglas de Firewall
echo -e "\n${GREEN}[4] REGLAS ACTIVAS DE IPTABLES${NC}" | tee -a "$REPORT_FILE"
if command -v iptables &> /dev/null; then sudo iptables -L -n -v --line-numbers | tee -a "$REPORT_FILE"; fi

# 5. Muestreo con tcpdump
echo -e "\n${GREEN}[5] MUESTREO DE TRÁFICO (5 SEGUNDOS)${NC}" | tee -a "$REPORT_FILE"
if command -v tcpdump &> /dev/null; then
    sudo tcpdump -i any -n -c 20 tcp or udp 2>&1 | tee -a "$REPORT_FILE" &
    TCPDUMP_PID=$!
    sleep 5
    kill $TCPDUMP_PID 2>/dev/null || true
fi

echo -e "\n${BLUE}[✓] Auditoría de red finalizada. Log: $REPORT_FILE${NC}"