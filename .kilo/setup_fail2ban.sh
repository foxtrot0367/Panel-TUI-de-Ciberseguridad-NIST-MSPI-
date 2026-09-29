#!/bin/bash
set -e

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[+] Instalando Fail2ban...${NC}"
sudo apt-get update -y
sudo apt-get install -y fail2ban

echo -e "${GREEN}[+] Configurando filtro Caddy WAF...${NC}"
cat << 'EOF' | sudo tee /etc/fail2ban/filter.d/caddy-waf.conf
[Definition]
failregex = ^.*"remote_ip":"<HOST>".*"status":(400|403|405).*$
ignoreregex =
EOF

echo -e "${GREEN}[+] Configurando Jail Local...${NC}"
cat << 'EOF' | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[caddy-waf]
enabled  = true
port     = http,https
filter   = caddy-waf
logpath  = /var/log/caddy/access.log
backend  = auto
action   = iptables-multiport[name=caddy-waf, port="http,https", protocol=tcp]
EOF

sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
echo -e "${GREEN}[✓] Fail2ban configurado y ejecutándose.${NC}"
