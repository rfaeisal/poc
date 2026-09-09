# POC-Pecek Backend API
## CLAUDE.md — Panduan lengkap untuk Claude Code

> REST API untuk platform PTT. Menangani auth, manajemen user/channel,
> LiveKit token generation, MQTT auth, dan webhook dari LiveKit.

---

## Tech Stack

| Teknologi | Versi | Fungsi |
|-----------|-------|--------|
| Node.js | 20 LTS | Runtime |
| Fastify | ^4.x | HTTP framework (lebih cepat dari Express) |
| PostgreSQL | 16 | Database utama |
| Redis | 7 | Cache, session, rate limiting |
| MQTT.js | ^5.x | Publish notifikasi ke Mosquitto |
| livekit-server-sdk | ^2.x | Generate LiveKit tokens, manage rooms |
| Zod | ^3.x | Validasi input |
| bcrypt | ^5.x | Hash password |
| jsonwebtoken | ^9.x | JWT auth |
| Prisma | ^5.x | ORM (database access) |
| Jest | ^29.x | Testing |
| Docker | - | Containerization |

---

## Struktur Direktori

```
backend/
├── CLAUDE.md                   # File ini
├── package.json
├── tsconfig.json
├── jest.config.ts
├── Dockerfile
├── .env.example
├── .env                        # Jangan di-commit
├── prisma/
│   ├── schema.prisma           # Database schema lengkap
│   └── migrations/             # Migration files (auto-generated)
├── src/
│   ├── app.ts                  # Fastify app factory
│   ├── server.ts               # Entry point (start server)
│   ├── config.ts               # Load & validate env vars
│   ├── plugins/
│   │   ├── auth.ts             # JWT plugin (fastify-jwt)
│   │   ├── cors.ts             # CORS config
│   │   ├── rate-limit.ts       # Rate limiting
│   │   ├── redis.ts            # Redis plugin
│   │   ├── prisma.ts           # Prisma plugin
│   │   └── mqtt.ts             # MQTT publisher plugin
│   ├── routes/
│   │   ├── auth/
│   │   │   ├── index.ts        # Register routes
│   │   │   ├── register.ts     # POST /auth/register
│   │   │   ├── login.ts        # POST /auth/login
│   │   │   ├── refresh.ts      # POST /auth/refresh
│   │   │   ├── logout.ts       # POST /auth/logout
│   │   │   └── me.ts           # GET /auth/me
│   │   ├── channels/
│   │   │   ├── index.ts
│   │   │   ├── list.ts         # GET /channels
│   │   │   ├── create.ts       # POST /channels
│   │   │   ├── get.ts          # GET /channels/:id
│   │   │   ├── update.ts       # PATCH /channels/:id
│   │   │   ├── delete.ts       # DELETE /channels/:id
│   │   │   ├── join.ts         # POST /channels/:id/join → LiveKit token
│   │   │   ├── leave.ts        # POST /channels/:id/leave
│   │   │   └── members.ts      # GET /channels/:id/members
│   │   ├── users/
│   │   │   ├── index.ts
│   │   │   ├── profile.ts      # GET/PATCH /users/:id/profile
│   │   │   ├── search.ts       # GET /users/search?q=callsign
│   │   │   └── devices.ts      # POST/GET /users/devices
│   │   ├── organizations/      # Enterprise: manajemen organisasi
│   │   │   ├── index.ts
│   │   │   ├── create.ts       # POST /organizations
│   │   │   ├── members.ts      # GET/POST /organizations/:id/members
│   │   │   └── settings.ts     # GET/PATCH /organizations/:id/settings
│   │   ├── admin/              # Admin-only routes
│   │   │   ├── index.ts
│   │   │   ├── users.ts        # List/ban/unban users
│   │   │   ├── channels.ts     # Force-close channels
│   │   │   └── stats.ts        # GET /admin/stats
│   │   └── webhook/
│   │       └── livekit.ts      # POST /webhook/livekit (dari LiveKit server)
│   ├── services/
│   │   ├── auth.service.ts     # Login, register, token management
│   │   ├── channel.service.ts  # CRUD channel + LiveKit room management
│   │   ├── livekit.service.ts  # Wrapper LiveKit server SDK
│   │   ├── mqtt.service.ts     # Publish MQTT events
│   │   ├── notification.service.ts  # Push notification (FCM)
│   │   └── audit.service.ts    # Log PTT events untuk enterprise
│   ├── middleware/
│   │   ├── authenticate.ts     # Verify JWT token
│   │   ├── authorize.ts        # Role-based access control
│   │   └── validate.ts         # Zod schema validation
│   └── lib/
│       ├── redis.ts            # Redis client singleton
│       ├── prisma.ts           # Prisma client singleton
│       ├── mqtt.ts             # MQTT client
│       └── livekit.ts          # LiveKit client
├── tests/
│   ├── auth.test.ts
│   ├── channels.test.ts
│   └── webhook.test.ts
└── scripts/
    └── seed.ts                 # Seed data untuk development
```

---

## Database Schema (Prisma)

Buat file `prisma/schema.prisma` dengan konten berikut:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ─────────────────────────────────────────
// ORGANIZATIONS — Enterprise multi-tenant
// ─────────────────────────────────────────
model Organization {
  id          String   @id @default(uuid())
  name        String
  slug        String   @unique  // Untuk subdomain atau identifier
  logoUrl     String?
  plan        OrgPlan  @default(FREE)
  maxUsers    Int      @default(100)
  maxChannels Int      @default(10)
  settings    Json     @default("{}")  // Konfigurasi tambahan
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  users    OrganizationMember[]
  channels Channel[]
  apiKeys  ApiKey[]
}

enum OrgPlan {
  FREE
  COMMUNITY     // Sampai 500 user
  ENTERPRISE    // Unlimited + SLA
}

// ─────────────────────────────────────────
// USERS
// ─────────────────────────────────────────
model User {
  id           String    @id @default(uuid())
  email        String    @unique
  passwordHash String
  role         UserRole  @default(USER)
  isActive     Boolean   @default(true)
  isBanned     Boolean   @default(false)
  bannedReason String?
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt
  lastSeenAt   DateTime?

  profile        UserProfile?
  organizations  OrganizationMember[]
  channelMembers ChannelMember[]
  devices        Device[]
  pttLogs        PttLog[]
  refreshTokens  RefreshToken[]
}

enum UserRole {
  USER
  MODERATOR
  ADMIN       // System admin
}

model UserProfile {
  id        String  @id @default(uuid())
  userId    String  @unique
  callsign  String  @unique  // Format: JZ12ABC
  name      String
  photoUrl  String?
  bio       String?
  latitude  Float?           // Lokasi terakhir (opsional)
  longitude Float?
  
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

// ─────────────────────────────────────────
// CHANNELS (=Rooms di LiveKit)
// ─────────────────────────────────────────
model Channel {
  id             String      @id @default(uuid())
  livekitRoomId  String      @unique  // Nama room di LiveKit
  name           String
  description    String?
  isPrivate      Boolean     @default(false)
  password       String?     // Hash password untuk channel privat
  maxMembers     Int         @default(500)
  isActive       Boolean     @default(true)
  createdAt      DateTime    @default(now())
  updatedAt      DateTime    @updatedAt

  organizationId String?
  organization   Organization? @relation(fields: [organizationId], references: [id])
  createdById    String
  
  members   ChannelMember[]
  pttLogs   PttLog[]
}

model ChannelMember {
  id        String            @id @default(uuid())
  channelId String
  userId    String
  role      ChannelMemberRole @default(MEMBER)
  joinedAt  DateTime          @default(now())
  isMuted   Boolean           @default(false)

  channel Channel @relation(fields: [channelId], references: [id], onDelete: Cascade)
  user    User    @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([channelId, userId])
}

enum ChannelMemberRole {
  MEMBER
  MODERATOR
  ADMIN
}

// ─────────────────────────────────────────
// PTT LOGS — Audit trail untuk enterprise
// ─────────────────────────────────────────
model PttLog {
  id          String   @id @default(uuid())
  channelId   String
  userId      String
  startedAt   DateTime
  endedAt     DateTime?
  durationMs  Int?
  audioUrl    String?  // Jika recording diaktifkan
  
  channel Channel @relation(fields: [channelId], references: [id])
  user    User    @relation(fields: [userId], references: [id])

  @@index([channelId, startedAt])
  @@index([userId, startedAt])
}

// ─────────────────────────────────────────
// DEVICES — Untuk push notification & audit
// ─────────────────────────────────────────
model Device {
  id         String   @id @default(uuid())
  userId     String
  deviceId   String             // IMEI atau UUID unik device
  fcmToken   String?            // Firebase Cloud Messaging token
  platform   DevicePlatform
  appVersion String
  lastSeenAt DateTime @default(now())
  createdAt  DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, deviceId])
}

enum DevicePlatform {
  ANDROID
  IOS
  DESKTOP
}

// ─────────────────────────────────────────
// REFRESH TOKENS
// ─────────────────────────────────────────
model RefreshToken {
  id        String   @id @default(uuid())
  userId    String
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())
  revokedAt DateTime?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([token])
}

// ─────────────────────────────────────────
// API KEYS — Untuk integrasi enterprise
// ─────────────────────────────────────────
model ApiKey {
  id             String       @id @default(uuid())
  organizationId String
  name           String       // Label untuk identifikasi
  keyHash        String       @unique
  permissions    String[]     // ["channels:read", "channels:write", dll]
  lastUsedAt     DateTime?
  expiresAt      DateTime?
  createdAt      DateTime     @default(now())
  revokedAt      DateTime?

  organization Organization @relation(fields: [organizationId], references: [id])
}

// ─────────────────────────────────────────
// ORGANIZATION MEMBERS
// ─────────────────────────────────────────
model OrganizationMember {
  id             String   @id @default(uuid())
  organizationId String
  userId         String
  role           OrgMemberRole @default(MEMBER)
  joinedAt       DateTime @default(now())

  organization Organization @relation(fields: [organizationId], references: [id])
  user         User         @relation(fields: [userId], references: [id])

  @@unique([organizationId, userId])
}

enum OrgMemberRole {
  MEMBER
  MANAGER
  OWNER
}
```

---

## Environment Variables (.env.example)

```env
# Server
NODE_ENV=development
PORT=3000
HOST=0.0.0.0

# Database
DATABASE_URL=postgresql://pocpecek:PASSWORD@localhost:5432/pocpecek

# Redis
REDIS_URL=redis://:PASSWORD@localhost:6379

# JWT
JWT_SECRET=                    # Min 32 karakter
JWT_ACCESS_EXPIRES=15m
JWT_REFRESH_SECRET=            # Min 32 karakter, berbeda dari JWT_SECRET
JWT_REFRESH_EXPIRES=30d

# LiveKit
LIVEKIT_URL=ws://localhost:7880
LIVEKIT_API_KEY=poc-api-key
LIVEKIT_API_SECRET=            # Harus sama dengan di infra/.env

# MQTT
MQTT_URL=mqtt://localhost:1883
MQTT_USERNAME=backend
MQTT_PASSWORD=

# PTT Config
PTT_MAX_DURATION_SECONDS=60    # Auto-release PTT setelah 60 detik
PTT_COOLDOWN_MS=500            # Cooldown antara transmisi

# Firebase (untuk push notification, opsional)
FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=

# SMTP (opsional)
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
SMTP_FROM=noreply@yourdomain.com

# Rate Limiting
RATE_LIMIT_MAX=100             # Max request per menit
RATE_LIMIT_WINDOW=60000        # Window dalam ms

# Cors
CORS_ORIGIN=http://localhost:5173,https://admin.yourdomain.com
```

---

## Semua Endpoint API

### Auth — `/auth`

| Method | Endpoint | Auth? | Body | Response |
|--------|----------|-------|------|----------|
| POST | `/auth/register` | ❌ | `{email, password, callsign, name}` | `{user, accessToken, refreshToken}` |
| POST | `/auth/login` | ❌ | `{email, password}` | `{user, accessToken, refreshToken}` |
| POST | `/auth/refresh` | ❌ | `{refreshToken}` | `{accessToken, refreshToken}` |
| POST | `/auth/logout` | ✅ | `{refreshToken}` | `{success: true}` |
| GET | `/auth/me` | ✅ | - | `{user, profile}` |
| PATCH | `/auth/me` | ✅ | `{name, bio, photoUrl}` | `{user}` |
| POST | `/auth/change-password` | ✅ | `{currentPassword, newPassword}` | `{success: true}` |

### Channels — `/channels`

| Method | Endpoint | Auth? | Keterangan |
|--------|----------|-------|------------|
| GET | `/channels` | ✅ | List semua channel publik + yang diikuti |
| POST | `/channels` | ✅ | Buat channel baru |
| GET | `/channels/:id` | ✅ | Detail channel |
| PATCH | `/channels/:id` | ✅ (admin) | Update channel |
| DELETE | `/channels/:id` | ✅ (admin) | Hapus channel |
| POST | `/channels/:id/join` | ✅ | Join channel → return LiveKit token |
| POST | `/channels/:id/leave` | ✅ | Leave channel |
| GET | `/channels/:id/members` | ✅ | List member yang online |
| POST | `/channels/:id/members/:userId/mute` | ✅ (mod) | Mute user |
| POST | `/channels/:id/members/:userId/kick` | ✅ (mod) | Kick user |
| GET | `/channels/:id/logs` | ✅ (enterprise) | PTT audit logs |

### Users — `/users`

| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/users/search?q=callsign` | Cari user berdasarkan callsign |
| GET | `/users/:id/profile` | Profil publik user |
| POST | `/users/devices` | Register device (untuk push notif) |
| DELETE | `/users/devices/:deviceId` | Hapus device |

### Organizations — `/organizations` (Enterprise)

| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/organizations` | Buat organisasi baru |
| GET | `/organizations/:id` | Detail organisasi |
| PATCH | `/organizations/:id` | Update settings |
| GET | `/organizations/:id/members` | List member |
| POST | `/organizations/:id/members` | Invite member |
| DELETE | `/organizations/:id/members/:userId` | Hapus member |
| POST | `/organizations/:id/api-keys` | Buat API key |
| GET | `/organizations/:id/api-keys` | List API keys |
| DELETE | `/organizations/:id/api-keys/:keyId` | Revoke API key |

### Admin — `/admin` (role: ADMIN only)

| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/admin/stats` | Statistik platform (user aktif, channel, dll) |
| GET | `/admin/users` | List semua user dengan filter |
| POST | `/admin/users/:id/ban` | Ban user |
| POST | `/admin/users/:id/unban` | Unban user |
| DELETE | `/admin/channels/:id` | Force-delete channel |

### Webhook — `/webhook`

| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/webhook/livekit` | Menerima event dari LiveKit server |

---

## LiveKit Token Generation

File: `src/services/livekit.service.ts`

```typescript
import { AccessToken } from 'livekit-server-sdk';

export async function generateChannelToken(
  userId: string,
  callsign: string,
  channelId: string,
  roomName: string,
  role: 'member' | 'moderator' | 'admin'
): Promise<string> {
  const at = new AccessToken(
    process.env.LIVEKIT_API_KEY!,
    process.env.LIVEKIT_API_SECRET!,
    {
      identity: userId,          // Identitas unik user
      name: callsign,            // Nama yang tampil
      ttl: '4h',                 // Token berlaku 4 jam
      metadata: JSON.stringify({
        callsign,
        channelId,
        role,
      }),
    }
  );

  at.addGrant({
    room: roomName,
    roomJoin: true,
    canPublish: true,           // Bisa transmit suara
    canSubscribe: true,         // Bisa dengar orang lain
    canPublishData: true,       // Bisa kirim data (PTT state, lokasi)
    roomAdmin: role === 'admin',
    roomRecord: role === 'admin', // Hanya admin bisa record
  });

  return at.toJwt();
}
```

---

## MQTT Topics Convention

```
# PTT Events
poc/channels/{channelId}/ptt           → Publish: {userId, callsign, action: "start"|"end"}
poc/channels/{channelId}/members       → Publish: {userId, callsign, action: "join"|"leave"}
poc/channels/{channelId}/status        → Publish: {activeUsers, isTransmitting, transmitterId}

# User Presence
poc/users/{userId}/presence            → Publish: {status: "online"|"offline", battery, signalStrength}
poc/users/{userId}/location            → Publish: {lat, lng, timestamp} (opsional, user opt-in)

# System Notifications
poc/system/announcements               → Broadcast dari admin
poc/organizations/{orgId}/alerts       → Alert untuk organisasi tertentu
```

---

## Webhook Handler (LiveKit Events)

File: `src/routes/webhook/livekit.ts`

Handler ini menerima event dari LiveKit dan update database + publish MQTT:

```typescript
// Event yang perlu dihandle:
// room_started        → Channel mulai aktif
// room_finished       → Channel kosong, bersihkan
// participant_joined  → User join channel → update ChannelMember + publish MQTT
// participant_left    → User leave channel → update ChannelMember + publish MQTT
// track_published     → User mulai transmit (PTT on) → catat PttLog.startedAt
// track_unpublished   → User stop transmit (PTT off) → catat PttLog.endedAt + durationMs
```

---

## Urutan Implementasi (untuk Claude Code)

Ikuti urutan ini:

1. **Setup project**: `npm init`, install dependencies, setup TypeScript
2. **Database**: Setup Prisma, buat schema, jalankan `prisma migrate dev`
3. **Config**: Buat `src/config.ts` untuk load env vars
4. **Plugins**: Buat semua plugin (redis, prisma, auth, cors, rate-limit)
5. **Auth routes**: Register, login, refresh, logout, me
6. **Channel routes**: CRUD + join (LiveKit token)
7. **Webhook**: Handler event dari LiveKit
8. **MQTT**: Publish events setelah webhook received
9. **User routes**: Profile, search, devices
10. **Organization routes**: Enterprise features
11. **Admin routes**: User management, stats
12. **Tests**: Unit tests untuk auth dan channel
13. **Dockerfile**: Containerize

---

## Perintah Development

```bash
# Install dependencies
npm install

# Setup database
npx prisma generate
npx prisma migrate dev --name init

# Seed data development
npx ts-node scripts/seed.ts

# Run development (dengan hot reload)
npm run dev

# Build untuk production
npm run build

# Run tests
npm test
npm run test:coverage

# Prisma Studio (GUI database)
npx prisma studio

# Format code
npm run lint
npm run format
```

---

## Dockerfile

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

FROM node:20-alpine AS production
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY prisma ./prisma

EXPOSE 3000
CMD ["node", "dist/server.js"]
```

---

## Security Checklist

- [ ] Password di-hash dengan bcrypt (rounds: 12)
- [ ] JWT secret min 32 karakter, berbeda untuk access dan refresh token
- [ ] Rate limiting aktif di semua endpoint auth
- [ ] CORS hanya untuk domain yang diizinkan
- [ ] Input validation dengan Zod di semua endpoint
- [ ] SQL injection: pakai Prisma (parameterized queries otomatis)
- [ ] Webhook LiveKit diverifikasi dengan signature
- [ ] API keys di-hash sebelum disimpan (tidak simpan plaintext)
- [ ] Refresh token rotation (setiap refresh → token baru, token lama invalidated)
- [ ] Helmet.js untuk HTTP security headers
