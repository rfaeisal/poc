#!/bin/bash
set -e

DOMAIN=$1
if [ -z "$DOMAIN" ]; then
    echo "Usage: bash setup.sh yourdomain.com"
    exit 1
fi

echo "Setting up POC-Pecek on $DOMAIN"

cd "$(dirname "$0")/.."

# Install dependencies
apt update && apt upgrade -y
apt install -y docker.io docker-compose-v2 certbot ufw fail2ban

# Firewall
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3478/udp
ufw allow 5349/tcp
ufw allow 7881/tcp
ufw allow 50000:60000/udp
ufw allow 8883/tcp
ufw --force enable

# SSL Certificate
certbot certonly --standalone \
    -d "$DOMAIN" \
    -d "api.$DOMAIN" \
    -d "livekit.$DOMAIN" \
    -d "turn.$DOMAIN" \
    -d "mqtt.$DOMAIN" \
    -d "admin.$DOMAIN" \
    --email "admin@$DOMAIN" \
    --agree-tos \
    --non-interactive

# Generate DH params (untuk TURN server)
openssl dhparam -out /etc/letsencrypt/dhparam.pem 2048

# Generate secrets
bash scripts/gen-secrets.sh

# Update DOMAIN di .env
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|DOMAIN=.*|DOMAIN=$DOMAIN|" .env
else
    sed -i "s|DOMAIN=.*|DOMAIN=$DOMAIN|" .env
fi

# Update DOMAIN di config files
find . -type f \( -name "*.conf" -o -name "*.yaml" -o -name "*.yml" \) \
    -exec sed -i "s/DOMAIN/$DOMAIN/g" {} \;

# Generate MQTT password file
source .env
docker run --rm -v "$(pwd)/mosquitto:/mosquitto/config" eclipse-mosquitto:2 \
    mosquitto_passwd -c -b /mosquitto/config/passwd "$MQTT_BACKEND_USER" "$MQTT_BACKEND_PASSWORD"

# Uncomment TLS lines in coturn config
sed -i 's/^# cert=/cert=/' coturn/turnserver.conf
sed -i 's/^# pkey=/pkey=/' coturn/turnserver.conf
sed -i 's/^# dh-file=/dh-file=/' coturn/turnserver.conf
sed -i "s/^# realm=.*/realm=turn.$DOMAIN/" coturn/turnserver.conf
sed -i "s/^# user=.*/user=$TURN_USERNAME:$TURN_PASSWORD/" coturn/turnserver.conf

# Uncomment TLS lines in mosquitto config
sed -i 's/^# listener 8883/listener 8883/' mosquitto/mosquitto.conf
sed -i 's/^# protocol mqtt$/protocol mqtt/' mosquitto/mosquitto.conf
sed -i 's/^# cafile/cafile/' mosquitto/mosquitto.conf
sed -i 's/^# certfile/certfile/' mosquitto/mosquitto.conf
sed -i 's/^# keyfile/keyfile/' mosquitto/mosquitto.conf
sed -i 's/^# tls_version/tls_version/' mosquitto/mosquitto.conf

# Start services
docker compose up -d

echo "Setup selesai!"
echo "Grafana: https://admin.$DOMAIN/grafana"
echo "Grafana password: $(grep GRAFANA_PASSWORD .env | cut -d= -f2)"
