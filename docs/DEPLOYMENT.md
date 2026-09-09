# POC-Pecek — Deployment & Scaling Guide
## Dari Development hingga Enterprise Production

---

## Tier 1 — Komunitas (~100 user concurrent)

### Spesifikasi Server
- **1x VPS**: 4 vCPU, 8GB RAM, 100GB SSD NVMe
- **OS**: Ubuntu 22.04 LTS
- **Provider rekomendasi**: IDCloudHost (Jakarta), DigitalOcean SGP, Vultr SGP
- **Estimasi biaya**: $40–80/bulan

### Setup

```bash
# 1. SSH ke server
ssh root@YOUR_SERVER_IP

# 2. Clone repo
git clone https://github.com/yourorg/poc-pecek.git
cd poc-pecek/infra

# 3. Jalankan setup script
bash scripts/setup.sh yourdomain.com

# 4. Verifikasi semua service jalan
docker compose ps
```

### Domain & DNS

Buat A record di DNS provider:
```
@           → SERVER_IP  (yourdomain.com)
api         → SERVER_IP  (api.yourdomain.com)
livekit     → SERVER_IP  (livekit.yourdomain.com)
turn        → SERVER_IP  (turn.yourdomain.com)
mqtt        → SERVER_IP  (mqtt.yourdomain.com)
admin       → SERVER_IP  (admin.yourdomain.com)
```

---

## Tier 2 — Production (~500 user concurrent)

### Spesifikasi Server (3 VPS)

| Server | Spek | Fungsi |
|--------|------|--------|
| VPS App | 4 vCPU, 8GB RAM | Backend API + Nginx + Admin |
| VPS LiveKit | 8 vCPU, 16GB RAM | LiveKit SFU + coturn (dedicated) |
| VPS DB | 4 vCPU, 16GB RAM | PostgreSQL + Redis |

### Arsitektur

```
Internet → Cloudflare (WAF + DDoS protection)
    ↓
VPS App (api.domain, admin.domain)
    ├── Nginx (SSL termination)
    ├── Backend API
    └── → VPS DB (private network)
    └── → VPS LiveKit (private network)

VPS LiveKit (livekit.domain, turn.domain)
    ├── LiveKit Server
    └── coturn
    └── → VPS DB Redis (untuk LiveKit state)

VPS DB
    ├── PostgreSQL (data utama)
    └── Redis (cache + LiveKit state)
```

### Network Security (Private Network)

Gunakan private network/VLAN antara server:
```bash
# Di VPS App — backend bisa akses DB via private IP
DATABASE_URL=postgresql://pocpecek:pass@10.0.0.1:5432/pocpecek
REDIS_URL=redis://:pass@10.0.0.1:6379

# Di VPS LiveKit — LiveKit bisa akses Redis via private IP
# livekit.yaml:
# redis:
#   address: 10.0.0.1:6379
```

---

## Tier 3 — Enterprise (~1000+ user concurrent)

### Tambahan untuk Enterprise

**Load Balancer**
```
Cloudflare Load Balancer → 2x VPS App (aktif-aktif)
Sticky sessions untuk WebSocket connections
Health check setiap 30 detik
```

**LiveKit Horizontal Scaling**
```
LiveKit mendukung clustering via Redis
2x VPS LiveKit → Redis cluster bersama
Distribusi room otomatis antar node
```

**Database HA**
```
PostgreSQL: Primary + 1 Read Replica
Redis: Sentinel atau Redis Cluster
Backup otomatis setiap 6 jam ke object storage (S3/Cloudflare R2)
```

**Monitoring Stack**
```
Prometheus → scrape metrics dari semua service
Grafana → dashboard visualisasi
Alertmanager → notifikasi via Telegram/email jika ada issue
Uptime Kuma → external uptime monitoring
```

---

## CI/CD Pipeline

### GitHub Actions (`.github/workflows/deploy.yml`)

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run tests
        working-directory: backend
        run: |
          npm ci
          npm test
      
      - name: Build Docker image
        run: |
          docker build -t pocpecek-backend:${{ github.sha }} backend/
      
      - name: Deploy ke server
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_IP }}
          username: deploy
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /opt/poc-pecek
            git pull
            docker compose up -d --no-deps --build backend
            docker compose exec -T backend npx prisma migrate deploy
  
  deploy-admin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build admin portal
        working-directory: admin
        run: |
          npm ci
          npm run build
        env:
          VITE_API_BASE_URL: ${{ secrets.API_BASE_URL }}
      
      - name: Upload ke server
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.SERVER_IP }}
          username: deploy
          key: ${{ secrets.SSH_KEY }}
          source: "admin/dist/*"
          target: "/opt/poc-pecek/infra/admin/dist"
```

---

## SSL Certificate Auto-Renewal

```bash
# Crontab untuk auto-renewal (tambahkan di server)
crontab -e

# Tambahkan baris ini:
0 3 * * * certbot renew --quiet && docker compose -f /opt/poc-pecek/infra/docker-compose.yml restart nginx
```

---

## Backup Strategy

```bash
# Jadwal backup otomatis (crontab)
0 */6 * * * /opt/poc-pecek/infra/scripts/backup.sh

# Backup tersimpan di ./backups/
# Retention: 30 hari terakhir (auto-cleanup di backup.sh)

# Untuk enterprise: tambahkan upload ke S3/R2
aws s3 cp backup.sql.gz s3://your-bucket/backups/
```

---

## Estimasi Kapasitas & Biaya

| Tier | User Concurrent | Server Cost/bulan | Cocok untuk |
|------|----------------|-------------------|-------------|
| Komunitas | ~100 | $40–80 | Komunitas lokal, club radio |
| Production | ~500 | $150–250 | Organisasi, perusahaan menengah |
| Enterprise | ~2000+ | $500–1000+ | Korporasi, instansi pemerintah |

---

## Checklist Go-Live

### Teknis
- [ ] Semua service `healthy` di `docker compose ps`
- [ ] SSL valid di semua subdomain
- [ ] TURN server test: https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/
- [ ] PTT test end-to-end dari 2 device berbeda
- [ ] Test dari jaringan 4G (bukan hanya WiFi)
- [ ] Monitoring Grafana aktif
- [ ] Alert Telegram/email sudah dikonfigurasi
- [ ] Backup berjalan dan bisa di-restore

### Bisnis
- [ ] Terms of Service sudah ada
- [ ] Privacy Policy sudah ada (terutama untuk fitur lokasi)
- [ ] Kontak support tersedia
- [ ] Proses onboarding user sudah jelas
- [ ] Untuk enterprise: SLA didefinisikan
