# POC-Pecek Mobile — Handoff Document
## Untuk Tim Mobile Flutter

> Dokumen ini berisi semua yang dibutuhkan tim mobile untuk membangun
> aplikasi PTT (Push-to-Talk) Android/iOS menggunakan Flutter.

---

## Overview

Aplikasi HT digital berbasis LiveKit WebRTC. User bisa join channel (seperti channel radio),
tekan tombol PTT untuk bicara, dan dengar orang lain bicara secara real-time.

**Target utama**: Android (iOS later). APK yang sama dipakai untuk komunitas dan enterprise.

---

## Tech Stack

| Package | Versi | Fungsi |
|---------|-------|--------|
| flutter | 3.x | Framework |
| livekit_client | ^2.x | WebRTC PTT engine |
| flutter_riverpod | ^2.x | State management |
| go_router | ^13.x | Navigation |
| dio | ^5.x | HTTP client |
| flutter_secure_storage | ^9.x | Simpan token aman |
| mqtt_client | ^10.x | MQTT untuk presence |
| flutter_map | ^6.x | Peta OpenStreetMap |
| permission_handler | ^11.x | Izin mikrofon, lokasi |
| geolocator | ^11.x | GPS tracking |
| flutter_local_notifications | ^17.x | Notifikasi lokal |
| firebase_messaging | ^14.x | Push notification (FCM) |
| flutter_bluetooth_serial | ^0.4.x | Bluetooth PTT button |
| just_audio | ^0.9.x | Suara notifikasi PTT |
| shared_preferences | ^2.x | Settings lokal |
| connectivity_plus | ^6.x | Deteksi jaringan |
| battery_plus | ^6.x | Info baterai |
| wakelock_plus | ^1.x | Jaga layar tetap nyala saat PTT |

---

## Cara Konek ke Backend

### Base URLs

```
# Development lokal (emulator Android)
API_BASE_URL=http://10.0.2.2:3000
LIVEKIT_URL=ws://10.0.2.2:7880
MQTT_HOST=10.0.2.2
MQTT_PORT=1883

# Development lokal (device fisik, ganti IP laptop)
API_BASE_URL=http://192.168.x.x:3000
LIVEKIT_URL=ws://192.168.x.x:7880

# Production
API_BASE_URL=https://api.yourdomain.com
LIVEKIT_URL=wss://livekit.yourdomain.com
MQTT_HOST=mqtt.yourdomain.com
MQTT_PORT=8883
```

### Run Flutter

```bash
# Emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Device fisik
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000
```

---

## API Contract — Semua Endpoint

### Auth

```
POST /auth/register
  Body: { email, password, callsign, name }
  Response: { user, accessToken, refreshToken }

POST /auth/login
  Body: { email, password }
  Response: { user, accessToken, refreshToken }

POST /auth/refresh
  Body: { refreshToken }
  Response: { accessToken, refreshToken }  ← Token rotation!

POST /auth/logout
  Headers: Authorization: Bearer <accessToken>
  Body: { refreshToken }
  Response: { success: true }

GET /auth/me
  Headers: Authorization: Bearer <accessToken>
  Response: { user: { id, email, role, profile: { callsign, name, photoUrl, bio } } }

PATCH /auth/me
  Headers: Authorization: Bearer <accessToken>
  Body: { name?, bio?, photoUrl? }
  Response: { profile }

POST /auth/change-password
  Headers: Authorization: Bearer <accessToken>
  Body: { currentPassword, newPassword }
  Response: { success: true }
```

### Channels

```
GET /channels
  Headers: Authorization: Bearer <accessToken>
  Response: { channels: [{ id, name, description, isPrivate, _count: { members } }] }

POST /channels
  Headers: Authorization: Bearer <accessToken>
  Body: { name, description?, isPrivate, password?, maxMembers? }
  Response: { channel }

GET /channels/:id
  Headers: Authorization: Bearer <accessToken>
  Response: { channel: { ...detail, members: [{ user: { profile } }] } }

POST /channels/:id/join     ← PENTING: ini yang return LiveKit token
  Headers: Authorization: Bearer <accessToken>
  Body: { password? }       ← password hanya untuk channel privat
  Response: {
    channel,
    livekitToken: "eyJ...",  ← Pakai ini untuk connect ke LiveKit
    livekitUrl: "ws://..."   ← URL LiveKit server
  }

POST /channels/:id/leave
  Headers: Authorization: Bearer <accessToken>
  Response: { success: true }

GET /channels/:id/members
  Headers: Authorization: Bearer <accessToken>
  Response: { members: [{ user: { id, profile: { callsign, name } }, role, isMuted }] }
```

### Users

```
GET /users/search?q=JZ12
  Headers: Authorization: Bearer <accessToken>
  Response: { users: [{ callsign, name }] }

GET /users/:id/profile
  Headers: Authorization: Bearer <accessToken>
  Response: { profile: { callsign, name, photoUrl, bio } }

POST /users/devices
  Headers: Authorization: Bearer <accessToken>
  Body: { deviceId, fcmToken?, platform: "ANDROID"|"IOS", appVersion }
  Response: { device }

DELETE /users/devices/:deviceId
  Headers: Authorization: Bearer <accessToken>
  Response: { success: true }
```

### Health Check

```
GET /health
  Response: { status: "ok", timestamp: "2024-..." }
```

---

## Auth Flow

```
1. User register/login → dapat accessToken (15 menit) + refreshToken (30 hari)
2. Simpan keduanya di flutter_secure_storage
3. Setiap API call → kirim accessToken di header Authorization
4. Jika 401 → panggil /auth/refresh dengan refreshToken
5. Dapat accessToken + refreshToken baru (token rotation)
6. Jika refresh gagal → redirect ke login
```

### Auto-Refresh Interceptor (Dio)

```dart
// Pseudocode untuk auth interceptor
interceptor.onError = (error) {
  if (error.response?.statusCode == 401) {
    // 1. Ambil refreshToken dari SecureStorage
    // 2. POST /auth/refresh
    // 3. Simpan token baru
    // 4. Retry request original
    // 5. Jika refresh gagal → logout
  }
};
```

---

## Alur PTT (Push-to-Talk)

```
1. User buka app → login → GET /channels → tampilkan list channel
2. User tap channel → POST /channels/:id/join → dapat livekitToken + livekitUrl
3. Connect ke LiveKit: Room.connect(livekitUrl, livekitToken)
4. User tekan PTT:
   a. LocalAudioTrack.create() → publish ke Room
   b. LiveKit server kirim webhook ke backend
   c. Backend publish MQTT: poc/channels/{id}/ptt → { action: "start", callsign }
   d. Semua client subscribe MQTT → update UI "JZ12ABC is transmitting"
5. User lepas PTT:
   a. Unpublish audio track
   b. Backend publish MQTT: poc/channels/{id}/ptt → { action: "end" }
   c. Semua client update UI → idle
6. User leave channel → POST /channels/:id/leave → Room.disconnect()
```

---

## MQTT Topics — Subscribe Ini

```
# Wajib subscribe saat join channel:
poc/channels/{channelId}/ptt
  → { userId, callsign, action: "start"|"end", timestamp }
  → Untuk update UI siapa yang transmit

poc/channels/{channelId}/members
  → { userId, callsign, action: "join"|"leave", timestamp }
  → Untuk update list member online

poc/channels/{channelId}/status
  → { activeUsers, isTransmitting, transmitterId, timestamp }
  → Summary status channel

# Opsional:
poc/users/{myUserId}/presence
  → Publish status online/offline + baterai
  → { status: "online"|"offline", battery, signalStrength, timestamp }

poc/users/{myUserId}/location
  → Publish lokasi GPS (jika user opt-in)
  → { lat, lng, timestamp }
```

---

## LiveKit Audio Settings — PENTING

```dart
// Optimasi untuk PTT voice (bukan music/video call):
RoomOptions(
  adaptiveStream: true,
  dynacast: true,
  audioTrackPublishDefaults: AudioTrackPublishOptions(
    audioBitrate: 32000,    // 32kbps cukup untuk voice
    dtx: true,              // Hemat bandwidth saat diam
  ),
)

// Audio capture untuk PTT:
AudioCaptureOptions(
  noiseSuppression: true,   // Hilangkan background noise
  echoCancellation: true,
  autoGainControl: true,
)
```

---

## Struktur Direktori yang Direkomendasikan

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── app_config.dart         # URLs dari --dart-define
│   ├── router.dart             # GoRouter
│   └── theme.dart              # Dark + Light theme
├── core/
│   ├── api/
│   │   ├── api_client.dart     # Dio + interceptor
│   │   └── api_endpoints.dart
│   ├── auth/
│   │   ├── auth_storage.dart   # SecureStorage wrapper
│   │   └── auth_interceptor.dart
│   ├── mqtt/
│   │   ├── mqtt_client.dart
│   │   └── mqtt_topics.dart
│   └── livekit/
│       └── livekit_service.dart
├── features/
│   ├── auth/
│   │   ├── models/user.dart
│   │   ├── providers/auth_provider.dart
│   │   └── screens/{login,register,splash}_screen.dart
│   ├── channels/
│   │   ├── models/{channel,channel_member}.dart
│   │   ├── providers/{channels,channel_members}_provider.dart
│   │   └── screens/{channel_list,channel_detail}_screen.dart
│   ├── ptt/
│   │   ├── providers/ptt_provider.dart
│   │   └── widgets/{ptt_button,ptt_indicator,volume_meter}.dart
│   ├── map/
│   │   ├── providers/location_provider.dart
│   │   └── screens/map_screen.dart
│   ├── settings/
│   │   └── screens/{settings,audio_settings,bluetooth_settings}_screen.dart
│   └── profile/
│       └── screens/profile_screen.dart
└── shared/
    ├── widgets/{app_bar,loading_indicator,error_widget,signal_strength}.dart
    └── utils/{audio_utils,format_utils}.dart
```

---

## State Management (Riverpod)

```
AuthProvider
  ├── currentUser: User?
  ├── isAuthenticated: bool
  ├── login(email, password)
  ├── register(...)
  └── logout()

ChannelsProvider
  ├── channels: List<Channel>
  ├── activeChannel: Channel?
  ├── fetchChannels()
  └── joinChannel(channelId) → LiveKit token

PttProvider (INTI DARI SEMUA)
  ├── isTransmitting: bool         → Apakah SAYA sedang transmit
  ├── currentSpeaker: Member?      → Siapa yang transmit (dari MQTT)
  ├── room: Room?                  → LiveKit Room
  ├── participants: List<Participant>
  ├── startTransmit()              → Publish mic, kirim PTT_START
  ├── stopTransmit()               → Unpublish mic, kirim PTT_END
  └── muteAudio(bool)

LocationProvider
  ├── currentPosition: Position?
  ├── isSharing: bool
  ├── memberLocations: Map<userId, Position>
  ├── startSharing()               → Publish ke MQTT
  └── stopSharing()

SettingsProvider
  ├── micGain, speakerGain
  ├── voxEnabled, voxThreshold
  ├── bluetoothDeviceId
  └── saveSettings()
```

---

## Layar PTT Utama — PRIORITAS #1

```
┌─────────────────────────────────┐
│ ← Channel Name          🔇 ⚙️  │  AppBar
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐  │
│  │  [Foto] JZ12ABC           │  │  Siapa yang transmit
│  │  "JZ12ABC is transmitting"│  │  (animasi ring hijau)
│  └───────────────────────────┘  │
│                                 │
│  ─── Members Online (12) ────   │
│  [JZ11] [JZ22] [JZ33] [JZ44]   │  Avatar grid
│  [JZ55] [JZ66] [JZ77] ...      │
│                                 │
│  Signal: ████░ 4G  🔋 87%      │  Status bar
│                                 │
│  ┌───────────────────────────┐  │
│  │       [  PTT  ]           │  │  Tombol besar
│  │   Hold to Transmit        │  │  hold-to-talk
│  └───────────────────────────┘  │
│  VOX: OFF    Bluetooth: ON      │  Toggle
└─────────────────────────────────┘
```

**PTT Button behavior:**
- Long press & hold → transmit (release → stop)
- Double tap → toggle lock (transmit terus sampai tap lagi)
- Timeout otomatis 60 detik

---

## Android Permissions (AndroidManifest.xml)

```xml
<!-- WAJIB -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

<!-- OPSIONAL -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
```

**Foreground service** wajib diimplementasi agar PTT tetap jalan di background.

---

## Build Commands

```bash
# Development
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Release APK
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com \
  --dart-define=LIVEKIT_URL=wss://livekit.yourdomain.com \
  --dart-define=MQTT_HOST=mqtt.yourdomain.com

# App Bundle (Play Store)
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com \
  --dart-define=LIVEKIT_URL=wss://livekit.yourdomain.com \
  --dart-define=MQTT_HOST=mqtt.yourdomain.com
```

---

## Seed Data untuk Testing

Backend sudah ada seed data (jalankan `npm run seed` di backend/):

| Email | Password | Role | Callsign |
|-------|----------|------|----------|
| admin@pocptx.local | admin123 | ADMIN | ADMIN01 |
| user1@pocptx.local | test1234 | USER | JZ01TST |
| user2@pocptx.local | test1234 | USER | JZ02TST |
| user3@pocptx.local | test1234 | USER | JZ03TST |
| user4@pocptx.local | test1234 | USER | JZ04TST |
| user5@pocptx.local | test1234 | USER | JZ05TST |

Channel yang sudah ada:
- **Channel Umum** (publik) — admin + user1-3 sudah join
- **Channel Privat** (password: `secret`) — admin saja

---

## Prioritas Development

```
Sprint 1 — Core PTT
  1. Login/Register screen
  2. Channel list screen
  3. Join channel → connect LiveKit
  4. PTT button (hold-to-talk)
  5. Audio transmit/receive

Sprint 2 — Presence & Polish
  6. MQTT integration (siapa transmit, member online)
  7. PTT indicator UI (ring animasi)
  8. Member list di channel
  9. Leave channel
  10. Auto-reconnect saat koneksi putus

Sprint 3 — Features
  11. Foreground service
  12. VOX (voice-activated)
  13. Bluetooth PTT button
  14. Map/lokasi member
  15. Settings screen

Sprint 4 — Production Ready
  16. Push notification (FCM)
  17. Battery optimization
  18. Crash reporting
  19. Multi-device testing
  20. Release signing
```

---

## Catatan Penting

1. **Hanya 1 user boleh transmit per channel** — LiveKit + backend enforce ini.
   Jika ada orang lain transmit, tampilkan "Channel busy" dan disable tombol PTT.

2. **Token rotation** — Setiap refresh, refreshToken lama diinvalidasi.
   Jangan simpan refreshToken di memory saja, pakai SecureStorage.

3. **Audio bitrate 32kbps** — Ini voice, bukan musik. Hemat bandwidth.

4. **DTX (Discontinuous Transmission)** — Harus ON. Tidak kirim data saat diam.

5. **Timeout PTT 60 detik** — Auto-release jika user lupa lepas tombol.

6. **Test di jaringan lemah** — PTT harus tetap usable di 3G/edge.
