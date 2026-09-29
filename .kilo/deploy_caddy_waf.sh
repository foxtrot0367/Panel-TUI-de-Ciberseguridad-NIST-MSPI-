#!/bin/bash
set -e

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[+] Instalando Caddy Server y dependencias...${NC}"
sudo apt-get update -y
sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl

curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list

sudo apt-get update -y
sudo apt-get install -y caddy

echo -e "${GREEN}[+] Generando Caddyfile con Reglas WAF...${NC}"
cat << 'EOF' | sudo tee /etc/caddy/Caddyfile
:80, :443 {
    @disallowed_methods {
        not method GET POST PUT DELETE HEAD
    }
    respond @disallowed_methods "Método HTTP no permitido por política WAF" 405

    @bad_bots {
        header_regexp User-Agent "(sqlmap|nikto|nmap|masscan|dirbuster|gobuster)"
    }
    respond @bad_bots "Acceso denegado por reglas WAF" 403

    @suspicious_query {
        query_regexp "(union.*select|concat|exec|drop.*table|<script|%3Cscript|\.\./\.\.)"
    }
    respond @suspicious_query "Payload malicioso detectado" 400

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        X-XSS-Protection "1; mode=block"
        -Server
        Content-Security-Policy "default-src 'self';"
    }

    log {
        output file /var/log/caddy/access.log {
            roll_size 10mb
            roll_keep 5
        }
        format json
    }

    reverse_proxy localhost:8080
}
EOF

sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl restart caddy
sudo systemctl enable caddy
echo -e "${GREEN}[✓] Caddy WAF desplegado y activo.${NC}"