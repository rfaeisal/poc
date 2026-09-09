#!/bin/bash
set -e

echo "=== Setting up POC-Pecek on poc.fzdev.my.id ==="

cd "$(dirname "$0")/.."

DOMAIN="poc.fzdev.my.id"

# ─────────────────────────────────────────
# Swap (2GB) — wajib untuk VPS 1GB RAM
# ─────────────────────────────────────────
if [ ! -f /swapfile ]; then
    echo "Creating 2GB swap..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    sysctl vm.swappiness=10
    echo 'vm.swappiness=10' >> /etc/sysctl.conf
    echo "Swap created."
else
    echo "Swap already exists, skipping."
fi

# ─────────────────────────────────────────
# Install dependencies
# ─────────────────────────────────────────
apt update && apt upgrade -y
apt install -y docker.io docker-compose-v2 certbot ufw fail2ban

# ─────────────────────────────────────────
# Firewall
# ─────────────────────────────────────────
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 7881/tcp
ufw allow 50000:60000/udp
ufw --force enable

# ─────────────────────────────────────────
# SSL Certificate (single subdomain)
# ─────────────────────────────────────────
certbot certonly --standalone \
    -d "$DOMAIN" \
    --email "admin@fzdev.my.id" \
    --agree-tos \
    --non-interactive

# Copy certs ke volume nginx-ssl
mkdir -p /etc/letsencrypt

# ─────────────────────────────────────────
# Generate secrets (jika belum ada .env)
# ─────────────────────────────────────────
if [ ! -f .env ]; then
    bash scripts/gen-secrets.sh
fi

# Set domain di .env
sed -i "s|DOMAIN=.*|DOMAIN=$DOMAIN|" .env

# ─────────────────────────────────────────
# Generate MQTT password
# ─────────────────────────────────────────
source .env
rm -f mosquitto/passwd
docker run --rm -v "$(pwd)/mosquitto:/mosquitto/config" eclipse-mosquitto:2 \
    mosquitto_passwd -c -b /mosquitto/config/passwd "$MQTT_BACKEND_USER" "$MQTT_BACKEND_PASSWORD"

# ─────────────────────────────────────────
# Set LiveKit external IP
# ─────────────────────────────────────────
PUBLIC_IP=$(curl -s ifconfig.me)
sed -i "s/# external_ip: .*/external_ip: \"$PUBLIC_IP\"/" livekit/livekit.yaml

# ─────────────────────────────────────────
# Check DATABASE_URL
# ─────────────────────────────────────────
source .env
if [ -z "$DATABASE_URL" ]; then
    echo ""
    echo "DATABASE_URL belum diset di .env"
    echo "Buat database di https://neon.tech lalu isi DATABASE_URL di .env"
    echo "Contoh: DATABASE_URL=postgresql://user:pass@ep-xxx.aws.neon.tech/pocpecek?sslmode=require"
    echo ""
    echo "Setelah itu jalankan:"
    echo "  docker compose build backend"
    echo "  docker compose up -d"
    exit 1
fi

# ─────────────────────────────────────────
# Build & start
# ─────────────────────────────────────────
docker compose build backend
docker compose up -d

echo ""
echo "=== Setup selesai! ==="
echo "Admin:     https://$DOMAIN"
echo "API:       https://$DOMAIN/api"
echo "LiveKit:   wss://$DOMAIN/livekit"
echo "MQTT WS:   wss://$DOMAIN/mqtt"
echo "Server IP: $PUBLIC_IP"
echo ""
echo "Prisma migrations jalan otomatis saat backend start."
echo "Untuk seed: docker exec poc-backend npx prisma db seed"
