# POC-Pecek Admin Portal
## CLAUDE.md — Panduan lengkap untuk Claude Code

> Web dashboard untuk administrator platform: manajemen user, channel, organisasi,
> monitoring live, audit log PTT, dan konfigurasi sistem.

---

## Tech Stack

| Teknologi | Versi | Fungsi |
|-----------|-------|--------|
| React | 18.x | UI framework |
| Vite | 5.x | Build tool |
| TypeScript | 5.x | Type safety |
| TailwindCSS | 3.x | Styling |
| shadcn/ui | latest | Komponen UI |
| TanStack Query | 5.x | Server state + caching |
| TanStack Table | 8.x | Tabel data |
| React Hook Form + Zod | latest | Form + validasi |
| Recharts | 2.x | Grafik statistik |
| Zustand | 4.x | Client state |
| MQTT.js | 5.x | Real-time presence monitor |
| date-fns | 3.x | Format tanggal |
| livekit-client | 2.x | Monitor live channel |

---

## Struktur Direktori

```
admin/
├── CLAUDE.md                         # File ini
├── package.json
├── vite.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── index.html
├── .env.example
├── public/
│   └── favicon.ico
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── config.ts                     # API URL, environment config
    ├── router.tsx                    # Route definitions
    ├── api/
    │   ├── client.ts                 # Axios instance dengan interceptor
    │   ├── auth.ts                   # Auth API calls
    │   ├── users.ts                  # User management API
    │   ├── channels.ts               # Channel management API
    │   ├── organizations.ts          # Org management API
    │   └── stats.ts                  # Statistics API
    ├── stores/
    │   └── auth.store.ts             # Auth state (Zustand)
    ├── hooks/
    │   ├── useAuth.ts
    │   ├── useRealtime.ts            # MQTT hook untuk live updates
    │   └── useLiveKit.ts             # Monitor live channel
    ├── pages/
    │   ├── auth/
    │   │   └── LoginPage.tsx
    │   ├── dashboard/
    │   │   └── DashboardPage.tsx     # Overview + stats
    │   ├── users/
    │   │   ├── UsersPage.tsx         # List user + search + filter
    │   │   └── UserDetailPage.tsx    # Detail + edit + ban
    │   ├── channels/
    │   │   ├── ChannelsPage.tsx      # List channel
    │   │   ├── ChannelDetailPage.tsx # Detail + live monitor + kick
    │   │   └── CreateChannelPage.tsx
    │   ├── organizations/
    │   │   ├── OrganizationsPage.tsx
    │   │   └── OrgDetailPage.tsx
    │   ├── monitor/
    │   │   └── LiveMonitorPage.tsx   # Real-time monitoring semua channel
    │   ├── audit/
    │   │   └── AuditLogsPage.tsx     # PTT audit logs (enterprise)
    │   └── settings/
    │       └── SettingsPage.tsx
    ├── components/
    │   ├── layout/
    │   │   ├── AppLayout.tsx         # Sidebar + header
    │   │   ├── Sidebar.tsx
    │   │   └── Header.tsx
    │   ├── common/
    │   │   ├── DataTable.tsx         # TanStack Table wrapper
    │   │   ├── StatsCard.tsx         # Kartu statistik
    │   │   ├── LiveBadge.tsx         # Badge "LIVE" animasi
    │   │   └── ConfirmDialog.tsx     # Dialog konfirmasi aksi destruktif
    │   └── charts/
    │       ├── UserGrowthChart.tsx
    │       ├── PttActivityChart.tsx
    │       └── ChannelUsageChart.tsx
    └── types/
        ├── user.ts
        ├── channel.ts
        └── stats.ts
```

---

## Halaman & Fitur

### Dashboard (`/dashboard`)

```
┌────────────────────────────────────────────────────────┐
│  POC-Pecek Admin              👤 Super Admin  [Logout]   │
├──────────┬─────────────────────────────────────────────┤
│          │  Dashboard                                  │
│ 📊 Dashboard│                                          │
│ 👥 Users  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    │
│ 📻 Channels│  │ 1,234│ │  89  │ │  12  │ │ 456  │    │
│ 🏢 Orgs  │  │Users │ │Live  │ │Orgs  │ │Today │    │
│ 📡 Monitor│  │Total │ │Users │ │Active│ │ PTTs │    │
│ 📋 Audit  │  └──────┘ └──────┘ └──────┘ └──────┘    │
│ ⚙️ Settings│                                          │
│          │  [User Growth Chart — 30 hari]             │
│          │                                            │
│          │  [PTT Activity Heatmap per jam]            │
│          │                                            │
│          │  Active Channels Now:                      │
│          │  📻 Indonesia Utama  [42 users] [LIVE]     │
│          │  📻 Banten Channel   [12 users] [LIVE]     │
└──────────┴────────────────────────────────────────────┘
```

Stats yang ditampilkan:
- Total users (aktif/tidak aktif/banned)
- Users online sekarang
- Channel aktif sekarang
- Total PTT transmissions hari ini
- Grafik user growth (7/30/90 hari)
- Grafik PTT activity per jam
- Tabel channel paling aktif

### Users (`/users`)

- Tabel: callsign, nama, email, role, status, last seen, aksi
- Filter: role, status (aktif/banned), organisasi
- Search: by callsign, nama, email
- Aksi per user: lihat detail, ban, unban, ubah role, reset password
- Detail user: profil, device terdaftar, channel yang diikuti, history PTT

### Channels (`/channels`)

- Tabel: nama, status (live/idle), member count, created by, aksi
- Filter: publik/privat, live/idle, organisasi
- Buat channel baru dari admin
- Detail channel:
  - Info dasar + edit
  - List member yang sedang online (live dari MQTT)
  - Siapa yang sedang transmit (real-time)
  - Tombol: kick member, force-close channel, broadcast pesan

### Live Monitor (`/monitor`)

```
┌─────────────────────────────────────────────────────┐
│  LIVE MONITOR                      Auto-refresh: ON  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  📻 Indonesia Utama          [42 users]  ████ 78%  │
│     🎙️ JZ12ABC sedang transmit...                  │
│                                                     │
│  📻 Banten Channel           [12 users]  ██░░ 34%  │
│     ● Idle                                          │
│                                                     │
│  📻 KOM2Bali                 [ 8 users]  █░░░ 12%  │
│     🎙️ JZ99XYZ sedang transmit...                  │
│                                                     │
│  [+ 23 channels idle tidak ditampilkan]             │
└─────────────────────────────────────────────────────┘
```

Update real-time via MQTT. Tampilkan:
- Semua channel aktif (ada user online)
- Siapa yang sedang transmit di setiap channel
- Jumlah user per channel
- Usage gauge

### Audit Logs (`/audit`) — Enterprise

- Filter: channel, user, tanggal range, durasi
- Export ke CSV
- Kolom: timestamp, callsign, channel, durasi transmit
- Grafik pie: top 10 user paling sering transmit
- Total durasi transmit per user per hari

---

## Environment Variables

```env
VITE_API_BASE_URL=https://api.yourdomain.com
VITE_MQTT_URL=wss://mqtt.yourdomain.com:9001
VITE_LIVEKIT_URL=wss://livekit.yourdomain.com
VITE_APP_NAME=POC-Pecek Admin
```

---

## Perintah Development

```bash
# Install dependencies
npm install

# Development server
npm run dev

# Build production
npm run build

# Preview build
npm run preview

# Type check
npm run typecheck

# Lint
npm run lint
```

---

## Deployment (Static Files)

```bash
# Build
npm run build

# Output di dist/
# Copy ke nginx static folder
cp -r dist/ ../infra/admin/dist/

# Atau deploy ke Cloudflare Pages
npx wrangler pages deploy dist --project-name poc-pecek-admin
```

---

## Checklist Sebelum Production

- [ ] `VITE_API_BASE_URL` sudah pointing ke production API
- [ ] Auth guard sudah bekerja (redirect ke login jika belum auth)
- [ ] Role-based access: route `/admin/*` hanya untuk role ADMIN
- [ ] Semua aksi destruktif (ban, kick, delete) ada konfirmasi dialog
- [ ] Error handling dan loading states di semua halaman
- [ ] Build production berhasil tanpa TypeScript error
