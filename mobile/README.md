# POC-Pecek

Aplikasi HT (Handy Talky) digital Push-to-Talk berbasis Flutter. Menggunakan LiveKit WebRTC untuk audio real-time dan MQTT untuk presence/signaling.

## Tech Stack

| Teknologi | Fungsi |
|-----------|--------|
| Flutter 3.x / Dart ^3.12 | Framework |
| LiveKit (livekit_client) | WebRTC PTT audio engine |
| MQTT (mqtt_client) | Real-time presence & signaling |
| Riverpod | State management |
| GoRouter | Navigation |
| Dio | HTTP client + auto token refresh |
| Firebase (opsional) | FCM push notification, Crashlytics |
| flutter_map + OpenStreetMap | Peta lokasi member |

## Fitur

- **Push-to-Talk** — Hold to talk, double-tap to lock, 60s auto-release
- **Channel** — Join channel publik/privat, lihat member online
- **MQTT Presence** — Real-time siapa yang transmit, member join/leave
- **VOX** — Voice-activated transmission (auto-transmit saat bicara)
- **Bluetooth PTT** — External Bluetooth button untuk trigger transmit
- **Foreground Service** — PTT tetap aktif di background
- **Peta Lokasi** — OpenStreetMap dengan marker member (opt-in GPS)
- **Push Notification** — FCM untuk notifikasi channel (perlu Firebase setup)
- **Crash Reporting** — Firebase Crashlytics dengan graceful fallback
- **Battery Optimization** — Prompt untuk disable battery restriction
- **Auto-Reconnect** — LiveKit + MQTT reconnect otomatis saat koneksi putus
- **Dark Theme** — Material 3 dark theme default

## Prasyarat

- Flutter SDK 3.44+
- Android SDK (min API 24 / Android 7.0)
- Backend POC-Pecek running (API + LiveKit + MQTT)

## Quick Start

```bash
# Clone & install dependencies
cd mobile
flutter pub get

# Run ke server production (VPS)
flutter run \
  --dart-define=API_BASE_URL=https://poc.fzdev.my.id/api \
  --dart-define=LIVEKIT_URL=wss://poc.fzdev.my.id/livekit \
  --dart-define=MQTT_WS_URL=wss://poc.fzdev.my.id/mqtt

# Run ke local dev server (emulator)
flutter run

# Run ke local dev server (device fisik — ganti IP laptop)
flutter run \
  --dart-define=API_BASE_URL=http://192.168.x.x:3000 \
  --dart-define=LIVEKIT_URL=ws://192.168.x.x:7880 \
  --dart-define=MQTT_HOST=192.168.x.x
```

### Environment Variables (via --dart-define)

| Variable | Default | Keterangan |
|----------|---------|------------|
| `API_BASE_URL` | `http://10.0.2.2:3000` | Backend API URL |
| `LIVEKIT_URL` | `ws://10.0.2.2:7880` | LiveKit WebRTC server |
| `MQTT_HOST` | `10.0.2.2` | MQTT broker host (TCP mode) |
| `MQTT_PORT` | `1883` | MQTT broker port (TCP mode) |
| `MQTT_WS_URL` | _(kosong)_ | MQTT WebSocket URL — jika diset, override MQTT_HOST/PORT |

### Server Production

| Service | URL |
|---------|-----|
| API | `https://poc.fzdev.my.id/api` |
| LiveKit | `wss://poc.fzdev.my.id/livekit` |
| MQTT | `wss://poc.fzdev.my.id/mqtt` |
| Admin Panel | `https://poc.fzdev.my.id` |

## Build

```bash
# Debug APK (production server)
flutter build apk --debug \
  --dart-define=API_BASE_URL=https://poc.fzdev.my.id/api \
  --dart-define=LIVEKIT_URL=wss://poc.fzdev.my.id/livekit \
  --dart-define=MQTT_WS_URL=wss://poc.fzdev.my.id/mqtt

# Release APK
flutter build apk --release \
  --dart-define=API_BASE_URL=https://poc.fzdev.my.id/api \
  --dart-define=LIVEKIT_URL=wss://poc.fzdev.my.id/livekit \
  --dart-define=MQTT_WS_URL=wss://poc.fzdev.my.id/mqtt

# App Bundle (Play Store)
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://poc.fzdev.my.id/api \
  --dart-define=LIVEKIT_URL=wss://poc.fzdev.my.id/livekit \
  --dart-define=MQTT_WS_URL=wss://poc.fzdev.my.id/mqtt
```

## Release Signing

1. Generate keystore:
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks \
     -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

2. Copy template dan isi password:
   ```bash
   cp android/key.properties.example android/key.properties
   # Edit android/key.properties dengan password yang benar
   ```

3. Build release — signing config otomatis terpakai jika `key.properties` ada.

## Firebase Setup (Opsional)

App berjalan normal tanpa Firebase. Untuk mengaktifkan FCM + Crashlytics:

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Buat project di [Firebase Console](https://console.firebase.google.com)

3. Konfigurasi:
   ```bash
   flutterfire configure --project=<your-project-id>
   ```
   Ini akan overwrite `lib/core/firebase/firebase_options.dart` dengan nilai asli.

4. Rebuild — Firebase features otomatis aktif.

## Struktur Project

```
lib/
├── main.dart                          # Entry point, error boundaries
├── app.dart                           # MaterialApp.router
├── config/
│   ├── app_config.dart                # Environment config (--dart-define)
│   ├── router.dart                    # GoRouter routes
│   └── theme.dart                     # Material 3 dark/light theme
├── core/
│   ├── api/
│   │   ├── api_client.dart            # Dio + auth interceptor
│   │   └── api_endpoints.dart         # REST endpoint paths
│   ├── auth/
│   │   ├── auth_interceptor.dart      # Auto token refresh pada 401
│   │   └── auth_storage.dart          # SecureStorage wrapper
│   ├── firebase/
│   │   ├── firebase_guard.dart        # Firebase optional init
│   │   └── firebase_options.dart      # Placeholder (replace via flutterfire)
│   ├── livekit/
│   │   └── livekit_service.dart       # LiveKit room + audio track
│   ├── mqtt/
│   │   ├── mqtt_service.dart          # MQTT client + auto-reconnect
│   │   └── mqtt_topics.dart           # Topic path helpers
│   ├── providers/
│   │   └── auth_side_effects.dart     # FCM + Crashlytics on auth change
│   └── services/
│       ├── battery_optimization_service.dart
│       ├── bluetooth_ptt_service.dart
│       ├── crash_reporting_service.dart
│       ├── device_info_service.dart
│       ├── foreground_service.dart
│       ├── push_notification_service.dart
│       └── vox_service.dart
├── features/
│   ├── auth/
│   │   ├── models/user.dart
│   │   ├── providers/auth_provider.dart
│   │   └── screens/                   # Splash, Login, Register
│   ├── channels/
│   │   ├── models/                    # Channel, ChannelMember
│   │   ├── providers/                 # Channels, ChannelMembers
│   │   └── screens/                   # ChannelList, ChannelDetail (PTT)
│   ├── map/
│   │   ├── providers/location_provider.dart
│   │   └── screens/map_screen.dart
│   ├── ptt/
│   │   ├── providers/ptt_provider.dart
│   │   └── widgets/                   # PttButton, PttIndicator
│   └── settings/
│       ├── providers/settings_provider.dart
│       └── screens/                   # Settings, Audio, Bluetooth, DeviceInfo
└── shared/
    └── widgets/                       # ConnectivityBanner, LoadingIndicator
```

## Test Accounts

| Email | Password | Callsign |
|-------|----------|----------|
| admin@pocpecek.local | admin123 | ADMIN01 |
| user1@pocpecek.local | test1234 | JZ01TST |
| user2@pocpecek.local | test1234 | JZ02TST |
| user3@pocpecek.local | test1234 | JZ03TST |
| user4@pocpecek.local | test1234 | JZ04TST |
| user5@pocpecek.local | test1234 | JZ05TST |

Channel yang tersedia:
- **Channel Umum** (publik) — user1-3 sudah join
- **Channel Privat** (private)

## Audio Settings

| Parameter | Nilai |
|-----------|-------|
| Bitrate | 32 kbps (voice-optimized) |
| DTX | ON (hemat bandwidth saat diam) |
| Noise suppression | ON |
| Echo cancellation | ON |
| Auto gain control | ON |
| PTT timeout | 60 detik |

## Catatan

- Hanya 1 user bisa transmit per channel pada satu waktu
- Token rotation: setiap refresh, refreshToken lama diinvalidasi
- AGP didowngrade ke 8.9.1 untuk kompatibilitas flutter_bluetooth_serial
- Firebase bersifat opsional — app berjalan penuh tanpa konfigurasi Firebase
