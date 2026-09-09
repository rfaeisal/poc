# POC-Pecek — Push-to-Talk Platform
## Master Architecture Document

> Platform PTT (Push-to-Talk) berbasis LiveKit WebRTC untuk komunitas dan enterprise Indonesia.
> Dokumen ini adalah **source of truth** untuk seluruh sub-project.

---

## Gambaran Sistem

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Flutter App  │  │ Admin Portal │  │  HT POC (Android)    │  │
│  │ (Android/iOS)│  │  (React Web) │  │  (same APK)          │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
└─────────┼─────────────────┼──────────────────────┼─────────────┘
          │                 │                      │
          ▼                 ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    NGINX REVERSE PROXY (SSL)                    │
│              api.yourdomain.com / app.yourdomain.com            │
└────┬──────────────────┬──────────────────────┬──────────────────┘
     │                  │                      │
     ▼                  ▼                      ▼
┌─────────┐     ┌──────────────┐     ┌────────────────┐
│ Backend │     │ LiveKit SFU  │     │  Admin Portal  │
│   API   │     │   Server     │     │  (React static)│
│(Fastify)│     │  :7880/:7881 │     │                │
└────┬────┘     └──────┬───────┘     └────────────────┘
     │                 │
     ▼                 ▼
┌─────────┐     ┌──────────────┐     ┌────────────────┐
│Postgres │     │ TURN Server  │     │ MQTT Broker    │
│  :5432  │     │  (coturn)    │     │ (Mosquitto)    │
└─────────┘     │  :3478/:5349 │     │   :1883/:8883  │
                └──────────────┘     └────────────────┘
                                     ┌────────────────┐
                                     │     Redis      │
                                     │    :6379       │
                                     └────────────────┘
```

---

## Sub-Projects

| Project | Path | Teknologi | Port |
|---------|------|-----------|------|
| Infrastructure | `infra/` | Docker Compose, LiveKit, coturn, MQTT | - |
| Backend API | `backend/` | Node.js, Fastify, PostgreSQL, Redis | 3000 |
| Mobile App | `mobile/` | Flutter, livekit_client | - |
| Admin Portal | `admin/` | React, Vite, TailwindCSS | 5173 |

---

## Domain & Endpoint Convention

```
# Production
api.yourdomain.com          → Backend API
livekit.yourdomain.com      → LiveKit Server (WSS)
turn.yourdomain.com         → TURN Server
mqtt.yourdomain.com         → MQTT Broker (WSS)
admin.yourdomain.com        → Admin Portal

# Development (local)
localhost:3000              → Backend API
localhost:7880              → LiveKit Server
localhost:3478              → TURN Server
localhost:1883              → MQTT Broker
localhost:5173              → Admin Portal
```

---

## Core Concepts

### Channel (Room)
Setara dengan "channel" di HT/radio. Satu channel = satu LiveKit Room.
- Channel bisa **publik** (siapa saja bisa join) atau **privat** (perlu password/invite)
- Channel punya **admin** (bisa kick, mute user lain)
- Maksimal **500 user per channel** (bisa dikonfigurasi)

### User & Callsign
- Setiap user punya **callsign** unik (misal: `JZ12ABC`)
- User bisa punya **role**: `user`, `moderator`, `admin`
- Enterprise: user dikaitkan ke **organisasi**

### PTT (Push-to-Talk)
- Hanya **satu user** boleh transmit di satu waktu per channel
- Pakai LiveKit **exclusive speaker lock** via metadata
- Timeout otomatis 60 detik jika PTT tidak dilepas

### Presence & MQTT
- MQTT dipakai untuk:
  - Notifikasi siapa sedang transmit
  - Join/leave channel
  - Status baterai device
  - Lokasi GPS (opsional)

---

## Database Schema (Overview)

```sql
-- Lihat backend/CLAUDE.md untuk schema lengkap

organizations     -- Enterprise: organisasi/perusahaan
users             -- User account
user_profiles     -- Callsign, foto, bio
channels          -- Channel/room
channel_members   -- Siapa saja yang ada di channel
channel_messages  -- Pesan teks (opsional)
ptt_logs          -- Log siapa transmit kapan (audit enterprise)
devices           -- Device yang terdaftar (IMEI/token)
api_keys          -- Untuk integrasi pihak ketiga
```

---

## Auth Flow

```
1. User register/login → Backend API → JWT Access Token (15 menit) + Refresh Token (30 hari)
2. User join channel → Backend API → LiveKit Access Token (dari LIVEKIT_API_SECRET)
3. Client connect → LiveKit Server (pakai LiveKit token)
4. Client subscribe MQTT → pakai JWT token
```

---

## Environment Variables Utama

Setiap sub-project punya `.env.example`-nya sendiri. Variabel yang **shared**:

```env
# Dipakai di backend dan mobile (via API)
LIVEKIT_URL=wss://livekit.yourdomain.com
LIVEKIT_API_KEY=your-api-key
LIVEKIT_API_SECRET=your-api-secret

MQTT_URL=mqtts://mqtt.yourdomain.com:8883
JWT_SECRET=your-jwt-secret-min-32-chars
```

---

## Deployment Target

### Minimum (Komunitas, ~100 user concurrent)
- 1x VPS: 4 vCPU, 8GB RAM, 100GB SSD
- OS: Ubuntu 22.04 LTS
- Semua service jalan via Docker Compose

### Production (Enterprise, ~1000 user concurrent)
- 1x VPS Backend API: 4 vCPU, 8GB RAM
- 1x VPS LiveKit: 8 vCPU, 16GB RAM (dedicated untuk SFU)
- 1x VPS Database: 4 vCPU, 16GB RAM (PostgreSQL + Redis)
- CDN untuk Admin Portal (Cloudflare Pages)
- Monitoring: Grafana + Prometheus

---

## Urutan Development yang Disarankan

```
1. infra/      → Setup semua service lokal dulu
2. backend/    → API + auth + LiveKit token generation
3. mobile/     → Flutter app connect ke backend + LiveKit
4. admin/      → Admin portal untuk manage user/channel
```

---

## Referensi

- LiveKit Docs: https://docs.livekit.io
- LiveKit Flutter SDK: https://pub.dev/packages/livekit_client
- LiveKit Server API: https://docs.livekit.io/reference/server-api
- coturn: https://github.com/coturn/coturn
- Mosquitto: https://mosquitto.org/documentation/
- Fastify: https://fastify.dev/docs/latest/
