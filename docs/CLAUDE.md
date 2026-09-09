# POC-Pecek — CLAUDE.md (Root)
## Dibaca Claude Code saat membuka project ini

> Platform PTT (Push-to-Talk) berbasis LiveKit WebRTC.
> Ini adalah **mono-repo** dengan 4 sub-project.

---

## Struktur Mono-Repo

```
poc-pecek/
├── CLAUDE.md          ← File ini (dibaca pertama oleh Claude Code)
├── ARCHITECTURE.md    ← Gambaran sistem lengkap (BACA INI DULU)
├── infra/
│   └── CLAUDE.md      ← Detail infrastruktur Docker
├── backend/
│   └── CLAUDE.md      ← Detail Backend API (Node.js + Fastify)
├── mobile/
│   └── CLAUDE.md      ← Detail Flutter Android App
└── admin/
    └── CLAUDE.md      ← Detail Admin Portal (React)
```

---

## Cara Membaca Dokumentasi Ini

1. **Baca `ARCHITECTURE.md`** untuk gambaran sistem keseluruhan
2. **Pilih sub-project** yang akan dikerjakan
3. **Baca `CLAUDE.md` di folder sub-project** untuk detail lengkap
4. Setiap `CLAUDE.md` berisi: stack, struktur file, schema, endpoint, perintah, checklist

---

## Urutan Development yang Benar

```
Step 1: infra/    → Jalankan semua service lokal (Docker Compose)
Step 2: backend/  → Buat API, auth, LiveKit token
Step 3: mobile/   → Flutter app (connect ke backend + LiveKit)
Step 4: admin/    → Admin portal React
```

---

## Quick Start (Development Lokal)

```bash
# 1. Clone / buka project
cd poc-pecek

# 2. Setup infrastruktur
cd infra
cp .env.example .env
# Edit .env — isi LIVEKIT_API_KEY, LIVEKIT_API_SECRET, dll
docker compose up -d
cd ..

# 3. Backend API
cd backend
npm install
cp .env.example .env
# Edit .env — isi DATABASE_URL, LIVEKIT_*, dll
npx prisma migrate dev
npm run dev
cd ..

# 4. Mobile (buka emulator dulu)
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
cd ..

# 5. Admin Portal
cd admin
npm install
cp .env.example .env
npm run dev
```

---

## Teknologi Utama (Ringkasan)

| Layer | Teknologi |
|-------|-----------|
| Voice/WebRTC | LiveKit SFU |
| NAT Traversal | coturn (TURN/STUN) |
| Presence/Notif | Mosquitto MQTT |
| Backend | Node.js + Fastify + Prisma |
| Database | PostgreSQL 16 |
| Cache | Redis 7 |
| Mobile | Flutter 3 + livekit_client |
| Admin | React 18 + Vite + TailwindCSS |
| Proxy/SSL | Nginx + Let's Encrypt |
| Container | Docker Compose |
| Monitoring | Prometheus + Grafana |

---

## Aturan Coding

- **Backend**: TypeScript strict, Zod untuk validasi semua input, Prisma untuk semua query DB
- **Mobile**: Flutter dengan Riverpod, tidak ada state management global selain Provider
- **Admin**: TypeScript strict, TanStack Query untuk semua server state
- **Semua**: Jangan hardcode credential, semua dari environment variable
- **Commit**: Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`)

---

## Jika Ada Error atau Stuck

1. Cek log service: `docker compose logs -f [service-name]`
2. Pastikan semua env var terisi di `.env`
3. Pastikan port tidak bentrok: 3000, 5432, 6379, 7880, 1883, 5173
4. Untuk LiveKit tidak konek: pastikan IP publik diisi di `livekit.yaml`
5. Untuk MQTT auth gagal: regenerate password file dan restart mosquitto
