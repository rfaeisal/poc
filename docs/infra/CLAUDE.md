# POC-Pecek Infrastructure
## CLAUDE.md — Panduan lengkap untuk Claude Code

> Project ini mengatur semua infrastruktur: LiveKit SFU, coturn TURN server,
> Mosquitto MQTT, PostgreSQL, Redis, dan Nginx. Semua dijalankan via Docker Compose.

---

## Tech Stack

| Service | Image | Fungsi |
|---------|-------|--------|
| LiveKit | `livekit/livekit-server:latest` | WebRTC SFU untuk voice |
| coturn | `coturn/coturn:latest` | TURN/STUN server (NAT traversal) |
| Mosquitto | `eclipse-mosquitto:2` | MQTT broker (presence/notifikasi) |
| PostgreSQL | `postgres:16-alpine` | Database utama |
| Redis | `redis:7-alpine` | Cache + session |
| Nginx | `nginx:alpine` | Reverse proxy + SSL termination |
| Certbot | `certbot/certbot` | SSL certificate (Let's Encrypt) |

---

## Struktur File yang Harus Dibuat

```
infra/
├── docker-compose.yml          # Semua service
├── docker-compose.prod.yml     # Override untuk production
├── .env.example                # Template environment variables
├── .env                        # Actual env (jangan di-commit!)
├── livekit/
│   └── livekit.yaml            # Konfigurasi LiveKit server
├── coturn/
│   └── turnserver.conf         # Konfigurasi coturn
├── mosquitto/
│   ├── mosquitto.conf          # Konfigurasi MQTT broker
│   ├── passwd                  # MQTT credentials (generated)
│   └── acl                     # MQTT access control list
├── nginx/
│   ├── nginx.conf              # Main nginx config
│   ├── conf.d/
│   │   ├── api.conf            # Reverse proxy ke backend
│   │   ├── livekit.conf        # Reverse proxy ke LiveKit
│   │   ├── mqtt.conf           # WebSocket proxy ke MQTT
│   │   └── admin.conf          # Static files admin portal
│   └── ssl/                    # SSL certificates (gitignored)
├── postgres/
│   └── init.sql                # Database initialization
├── scripts/
│   ├── setup.sh                # One-command setup untuk server baru
│   ├── deploy.sh               # Deploy ulang setelah update
│   ├── backup.sh               # Backup database
│   ├── restore.sh              # Restore dari backup
│   └── gen-secrets.sh          # Generate semua secret otomatis
└── monitoring/
    ├── prometheus.yml          # Prometheus config
    └── grafana/
        └── dashboards/
            └── poc-pecek.json    # Grafana dashboard
```

---

## File: docker-compose.yml

Buat file ini dengan konten berikut (lengkap, production-ready):

```yaml
version: '3.9'

networks:
  poc-pecek-net:
    driver: bridge

volumes:
  postgres-data:
  redis-data:
  mosquitto-data:
  livekit-data:
  nginx-ssl:
  prometheus-data:
  grafana-data:

services:

  # ─────────────────────────────────────────
  # PostgreSQL — Database utama
  # ─────────────────────────────────────────
  postgres:
    image: postgres:16-alpine
    container_name: poc-postgres
    restart: unless-stopped
    networks: [poc-pecek-net]
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-pocpecek}
      POSTGRES_USER: ${POSTGRES_USER:-pocpecek}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-pocpecek}"]
      interval: 10s
      timeout: 5s
      retries: 5
    ports:
      - "127.0.0.1:5432:5432"  # Hanya localhost, tidak expose ke publik

  # ─────────────────────────────────────────
  # Redis — Cache + Session + Pub/Sub internal
  # ─────────────────────────────────────────
  redis:
    image: redis:7-alpine
    container_name: poc-redis
    restart: unless-stopped
    networks: [poc-pecek-net]
    command: redis-server --requirepass ${REDIS_PASSWORD} --maxmemory 512mb --maxmemory-policy allkeys-lru
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    ports:
      - "127.0.0.1:6379:6379"

  # ─────────────────────────────────────────
  # LiveKit — WebRTC SFU (core PTT engine)
  # ─────────────────────────────────────────
  livekit:
    image: livekit/livekit-server:latest
    container_name: poc-livekit
    restart: unless-stopped
    networks: [poc-pecek-net]
    command: --config /etc/livekit.yaml
    volumes:
      - ./livekit/livekit.yaml:/etc/livekit.yaml:ro
    ports:
      - "7880:7880"   # HTTP/WebSocket API
      - "7881:7881"   # RTC over TCP
      - "50000-60000:50000-60000/udp"  # UDP media range
    depends_on:
      redis:
        condition: service_healthy
    environment:
      - LIVEKIT_API_KEY=${LIVEKIT_API_KEY}
      - LIVEKIT_API_SECRET=${LIVEKIT_API_SECRET}

  # ─────────────────────────────────────────
  # coturn — TURN/STUN server untuk NAT traversal
  # ─────────────────────────────────────────
  coturn:
    image: coturn/coturn:latest
    container_name: poc-coturn
    restart: unless-stopped
    network_mode: host  # TURN butuh host network untuk NAT traversal yang benar
    volumes:
      - ./coturn/turnserver.conf:/etc/turnserver.conf:ro
      - nginx-ssl:/etc/ssl/letsencrypt:ro
    command: -c /etc/turnserver.conf

  # ─────────────────────────────────────────
  # Mosquitto — MQTT broker untuk presence & notifikasi
  # ─────────────────────────────────────────
  mosquitto:
    image: eclipse-mosquitto:2
    container_name: poc-mosquitto
    restart: unless-stopped
    networks: [poc-pecek-net]
    volumes:
      - ./mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf:ro
      - ./mosquitto/passwd:/mosquitto/config/passwd:ro
      - ./mosquitto/acl:/mosquitto/config/acl:ro
      - mosquitto-data:/mosquitto/data
      - nginx-ssl:/etc/ssl/letsencrypt:ro
    ports:
      - "1883:1883"    # MQTT (internal only, tidak expose ke publik kecuali dev)
      - "8883:8883"    # MQTT over TLS
      - "9001:9001"    # MQTT over WebSocket (untuk web client)

  # ─────────────────────────────────────────
  # Nginx — Reverse proxy + SSL
  # ─────────────────────────────────────────
  nginx:
    image: nginx:alpine
    container_name: poc-nginx
    restart: unless-stopped
    networks: [poc-pecek-net]
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - nginx-ssl:/etc/letsencrypt:ro
      - ./admin/dist:/var/www/admin:ro  # Static files admin portal
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - livekit
      - mosquitto

  # ─────────────────────────────────────────
  # Prometheus — Metrics collection
  # ─────────────────────────────────────────
  prometheus:
    image: prom/prometheus:latest
    container_name: poc-prometheus
    restart: unless-stopped
    networks: [poc-pecek-net]
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    ports:
      - "127.0.0.1:9090:9090"

  # ─────────────────────────────────────────
  # Grafana — Dashboard monitoring
  # ─────────────────────────────────────────
  grafana:
    image: grafana/grafana:latest
    container_name: poc-grafana
    restart: unless-stopped
    networks: [poc-pecek-net]
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
      - GF_SERVER_ROOT_URL=https://admin.${DOMAIN}/grafana
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards:ro
    ports:
      - "127.0.0.1:3001:3000"
    depends_on:
      - prometheus
```

---

## File: .env.example

```env
# ─── Domain ───────────────────────────────
DOMAIN=yourdomain.com
# Contoh: poc-indonesia.com

# ─── LiveKit ──────────────────────────────
LIVEKIT_API_KEY=poc-api-key
LIVEKIT_API_SECRET=           # Min 32 char, generate dengan: openssl rand -hex 32

# ─── Database ─────────────────────────────
POSTGRES_DB=pocpecek
POSTGRES_USER=pocpecek
POSTGRES_PASSWORD=            # Generate: openssl rand -hex 16

# ─── Redis ────────────────────────────────
REDIS_PASSWORD=               # Generate: openssl rand -hex 16

# ─── MQTT ─────────────────────────────────
MQTT_BACKEND_USER=backend
MQTT_BACKEND_PASSWORD=        # Generate: openssl rand -hex 16

# ─── TURN Server ──────────────────────────
TURN_USERNAME=poc-turn
TURN_PASSWORD=                # Generate: openssl rand -hex 16

# ─── Backend API ──────────────────────────
JWT_SECRET=                   # Generate: openssl rand -hex 32
JWT_REFRESH_SECRET=           # Generate: openssl rand -hex 32

# ─── Admin ────────────────────────────────
GRAFANA_PASSWORD=             # Password untuk Grafana dashboard

# ─── Email (opsional, untuk verifikasi) ───
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
SMTP_FROM=noreply@yourdomain.com
```

---

## File: livekit/livekit.yaml

```yaml
port: 7880
rtc:
  tcp_port: 7881
  port_range_start: 50000
  port_range_end: 60000
  use_external_ip: true
  # Masukkan IP publik server kamu
  # external_ip: "1.2.3.4"

keys:
  # Key diisi dari environment variable saat runtime
  # Format: api_key: api_secret

turn:
  enabled: true
  domain: turn.${DOMAIN}
  tls_port: 5349
  udp_port: 3478
  external_tls: true

redis:
  address: redis:6379
  password: ${REDIS_PASSWORD}

room:
  # Default settings untuk setiap room/channel
  max_participants: 500
  empty_timeout: 300          # Hapus room kosong setelah 5 menit
  departure_timeout: 20       # Tunggu 20 detik sebelum anggap user disconnect
  
webhook:
  # Kirim event ke backend untuk logging & audit
  urls:
    - http://backend:3000/webhook/livekit
  api_key: ${LIVEKIT_API_KEY}

logging:
  level: info
  json: true
```

---

## File: coturn/turnserver.conf

```conf
# Port
listening-port=3478
tls-listening-port=5349

# Binding
listening-ip=0.0.0.0
relay-ip=0.0.0.0

# External IP (ganti dengan IP publik server)
# external-ip=1.2.3.4

# TLS Certificate
cert=/etc/ssl/letsencrypt/live/DOMAIN/fullchain.pem
pkey=/etc/ssl/letsencrypt/live/DOMAIN/privkey.pem
dh-file=/etc/ssl/letsencrypt/dhparam.pem

# Auth
lt-cred-mech
user=TURN_USERNAME:TURN_PASSWORD

# Security
no-loopback-peers
no-multicast-peers
fingerprint
no-stdout-log
syslog

# Realm
realm=turn.DOMAIN

# Port range untuk relay
min-port=49152
max-port=65535

# Logging
log-file=/var/log/turnserver.log
verbose
```

---

## File: mosquitto/mosquitto.conf

```conf
# Listener MQTT biasa (internal)
listener 1883
protocol mqtt

# Listener MQTT over TLS
listener 8883
protocol mqtt
cafile /etc/ssl/letsencrypt/live/DOMAIN/chain.pem
certfile /etc/ssl/letsencrypt/live/DOMAIN/fullchain.pem
keyfile /etc/ssl/letsencrypt/live/DOMAIN/privkey.pem
tls_version tlsv1.2

# Listener MQTT over WebSocket
listener 9001
protocol websockets

# Auth
allow_anonymous false
password_file /mosquitto/config/passwd
acl_file /mosquitto/config/acl

# Persistence
persistence true
persistence_location /mosquitto/data/

# Logging
log_dest file /mosquitto/log/mosquitto.log
log_type all
```

---

## File: mosquitto/acl

```
# Format: user <username>
# topic read/write/readwrite <topic pattern>

# Backend API — bisa publish ke semua topic
user backend
topic readwrite #

# Pattern untuk user biasa:
# User hanya bisa publish ke topic presence milik sendiri
# dan subscribe ke channel yang mereka join
# (ACL dinamis dihandle di backend dengan token)

# Default: tidak ada akses
```

---

## File: nginx/conf.d/api.conf

```nginx
upstream backend_api {
    server backend:3000;
    keepalive 32;
}

server {
    listen 443 ssl http2;
    server_name api.DOMAIN;

    ssl_certificate /etc/letsencrypt/live/DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=63072000" always;

    location / {
        proxy_pass http://backend_api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Rate limiting
        limit_req zone=api burst=20 nodelay;
        limit_req_status 429;
    }
}
```

---

## File: nginx/conf.d/livekit.conf

```nginx
upstream livekit_server {
    server livekit:7880;
    keepalive 32;
}

server {
    listen 443 ssl http2;
    server_name livekit.DOMAIN;

    ssl_certificate /etc/letsencrypt/live/DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://livekit_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 3600s;    # WebSocket long-lived connection
        proxy_send_timeout 3600s;
    }
}
```

---

## File: postgres/init.sql

Script ini dijalankan otomatis saat postgres pertama kali start.
Buat extension yang dibutuhkan:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- Untuk full-text search callsign
CREATE EXTENSION IF NOT EXISTS "citext";     -- Case-insensitive text

-- Set timezone
SET timezone = 'Asia/Jakarta';
ALTER DATABASE pocpecek SET timezone = 'Asia/Jakarta';
```

---

## File: scripts/gen-secrets.sh

```bash
#!/bin/bash
# Generate semua secret dan tulis ke .env

set -e

if [ -f .env ]; then
    echo "⚠️  File .env sudah ada. Hapus dulu jika ingin generate ulang."
    exit 1
fi

cp .env.example .env

# Generate semua secret
LIVEKIT_SECRET=$(openssl rand -hex 32)
POSTGRES_PASSWORD=$(openssl rand -hex 16)
REDIS_PASSWORD=$(openssl rand -hex 16)
MQTT_BACKEND_PASSWORD=$(openssl rand -hex 16)
TURN_PASSWORD=$(openssl rand -hex 16)
JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
GRAFANA_PASSWORD=$(openssl rand -base64 12)

# Isi ke .env
sed -i "s|LIVEKIT_API_SECRET=.*|LIVEKIT_API_SECRET=$LIVEKIT_SECRET|" .env
sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$POSTGRES_PASSWORD|" .env
sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=$REDIS_PASSWORD|" .env
sed -i "s|MQTT_BACKEND_PASSWORD=.*|MQTT_BACKEND_PASSWORD=$MQTT_BACKEND_PASSWORD|" .env
sed -i "s|TURN_PASSWORD=.*|TURN_PASSWORD=$TURN_PASSWORD|" .env
sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
sed -i "s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET|" .env
sed -i "s|GRAFANA_PASSWORD=.*|GRAFANA_PASSWORD=$GRAFANA_PASSWORD|" .env

echo "✅ Secrets generated! Sekarang edit .env dan isi DOMAIN dan IP server."
```

---

## File: scripts/setup.sh

```bash
#!/bin/bash
# One-command setup untuk server Ubuntu 22.04 baru
# Jalankan sebagai root: bash setup.sh yourdomain.com

set -e

DOMAIN=$1
if [ -z "$DOMAIN" ]; then
    echo "Usage: bash setup.sh yourdomain.com"
    exit 1
fi

echo "🚀 Setting up POC-Pecek on $DOMAIN"

# Install dependencies
apt update && apt upgrade -y
apt install -y docker.io docker-compose-v2 certbot nginx-certbot ufw fail2ban

# Firewall
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3478/udp    # TURN UDP
ufw allow 5349/tcp    # TURN TLS
ufw allow 7881/tcp    # LiveKit RTC TCP
ufw allow 50000:60000/udp  # LiveKit media
ufw allow 8883/tcp    # MQTT TLS
ufw --force enable

# SSL Certificate
certbot certonly --standalone \
    -d $DOMAIN \
    -d api.$DOMAIN \
    -d livekit.$DOMAIN \
    -d turn.$DOMAIN \
    -d mqtt.$DOMAIN \
    -d admin.$DOMAIN \
    --email admin@$DOMAIN \
    --agree-tos \
    --non-interactive

# Generate DH params (untuk TURN server)
openssl dhparam -out /etc/letsencrypt/dhparam.pem 2048

# Generate secrets
bash scripts/gen-secrets.sh

# Update DOMAIN di config files
find . -type f \( -name "*.conf" -o -name "*.yaml" -o -name "*.yml" \) \
    -exec sed -i "s/DOMAIN/$DOMAIN/g" {} \;

# Generate MQTT password file
source .env
docker run --rm eclipse-mosquitto:2 \
    mosquitto_passwd -c -b /tmp/passwd $MQTT_BACKEND_USER $MQTT_BACKEND_PASSWORD
cp /tmp/passwd mosquitto/passwd

# Start services
docker compose up -d

echo "✅ Setup selesai!"
echo "📊 Grafana: https://admin.$DOMAIN/grafana"
echo "🔑 Grafana password: $(grep GRAFANA_PASSWORD .env | cut -d= -f2)"
```

---

## File: scripts/backup.sh

```bash
#!/bin/bash
# Backup database PostgreSQL ke file tar.gz

set -e
source .env

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"
mkdir -p $BACKUP_DIR

echo "📦 Backing up database..."
docker compose exec -T postgres pg_dump \
    -U $POSTGRES_USER \
    -d $POSTGRES_DB \
    --no-owner \
    --no-acl \
    | gzip > "$BACKUP_DIR/pocpecek_$TIMESTAMP.sql.gz"

echo "✅ Backup saved: $BACKUP_DIR/pocpecek_$TIMESTAMP.sql.gz"

# Hapus backup lebih dari 30 hari
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete
echo "🗑️  Old backups cleaned up"
```

---

## Perintah Penting (untuk Claude Code)

```bash
# Setup pertama kali (development)
cp .env.example .env
# Edit .env, isi semua nilai
bash scripts/gen-secrets.sh
docker compose up -d

# Cek status semua service
docker compose ps

# Lihat log service tertentu
docker compose logs -f livekit
docker compose logs -f postgres
docker compose logs -f mosquitto

# Restart service tertentu
docker compose restart livekit
docker compose restart backend

# Stop semua
docker compose down

# Stop dan hapus semua data (HATI-HATI di production!)
docker compose down -v

# Deploy ulang setelah update config
docker compose up -d --no-deps --build livekit

# Masuk ke PostgreSQL
docker compose exec postgres psql -U pocpecek -d pocpecek

# Masuk ke Redis CLI
docker compose exec redis redis-cli -a $REDIS_PASSWORD

# Generate MQTT password baru
docker compose exec mosquitto mosquitto_passwd -b /mosquitto/config/passwd <username> <password>
docker compose restart mosquitto

# Renew SSL certificate
certbot renew
docker compose restart nginx
```

---

## Checklist Sebelum Production

- [ ] Semua secret di `.env` sudah diisi (tidak ada yang kosong)
- [ ] DOMAIN sudah diisi dan DNS sudah pointing ke server
- [ ] SSL certificate sudah ada (`certbot certonly ...`)
- [ ] IP publik server sudah diisi di `livekit.yaml` (`external_ip`)
- [ ] IP publik server sudah diisi di `coturn/turnserver.conf` (`external-ip`)
- [ ] Firewall sudah dikonfigurasi (`ufw status`)
- [ ] `docker compose ps` semua service `Up (healthy)`
- [ ] Test koneksi LiveKit dari mobile app
- [ ] Test TURN server dengan webrtc.github.io/samples/src/content/peerconnection/trickle-ice/
- [ ] Backup script berjalan dengan benar
- [ ] Monitoring Grafana bisa diakses

---

## Troubleshooting Umum

### LiveKit tidak bisa connect dari luar
→ Pastikan `external_ip` di `livekit.yaml` sudah diisi IP publik server
→ Pastikan port UDP 50000-60000 terbuka di firewall
→ Test: `nc -zvu SERVER_IP 7880`

### MQTT tidak bisa connect
→ Cek password file: `docker compose exec mosquitto cat /mosquitto/config/passwd`
→ Pastikan ACL file sudah benar
→ Test: `mosquitto_pub -h localhost -p 1883 -u backend -P PASSWORD -t test -m hello`

### coturn tidak jalan
→ coturn pakai `network_mode: host`, pastikan tidak ada konflik port
→ Cek log: `docker compose logs coturn`
→ Pastikan path certificate sudah benar
