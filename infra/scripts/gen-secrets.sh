#!/bin/bash
set -e

cd "$(dirname "$0")/.."

if [ -f .env ]; then
    echo "File .env sudah ada. Hapus dulu jika ingin generate ulang."
    exit 1
fi

cp .env.example .env

LIVEKIT_SECRET=$(openssl rand -hex 32)
POSTGRES_PASSWORD=$(openssl rand -hex 16)
REDIS_PASSWORD=$(openssl rand -hex 16)
MQTT_BACKEND_PASSWORD=$(openssl rand -hex 16)
TURN_PASSWORD=$(openssl rand -hex 16)
JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
GRAFANA_PASSWORD=$(openssl rand -base64 12)

# macOS + Linux compatible sed -i
sedi() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

sedi "s|LIVEKIT_API_SECRET=.*|LIVEKIT_API_SECRET=$LIVEKIT_SECRET|" .env
sedi "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$POSTGRES_PASSWORD|" .env
sedi "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=$REDIS_PASSWORD|" .env
sedi "s|MQTT_BACKEND_PASSWORD=.*|MQTT_BACKEND_PASSWORD=$MQTT_BACKEND_PASSWORD|" .env
sedi "s|TURN_PASSWORD=.*|TURN_PASSWORD=$TURN_PASSWORD|" .env
sedi "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
sedi "s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET|" .env
sedi "s|GRAFANA_PASSWORD=.*|GRAFANA_PASSWORD=$GRAFANA_PASSWORD|" .env

echo "Secrets generated! Sekarang edit .env dan isi DOMAIN dan IP server."
