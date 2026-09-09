# POC-Pecek Mobile App
## CLAUDE.md — Panduan lengkap untuk Claude Code

> Aplikasi Android (dan iOS) Push-to-Talk menggunakan Flutter dan LiveKit.
> Mendukung PTT channel, Bluetooth tombol PTT, peta lokasi, dan notifikasi MQTT.

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

## Struktur Direktori

```
mobile/
├── CLAUDE.md                         # File ini
├── pubspec.yaml
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml   # Permissions + foreground service
│   │       └── kotlin/
│   │           └── MainActivity.kt
│   └── build.gradle
├── ios/
│   └── Runner/
│       └── Info.plist               # iOS permissions
├── lib/
│   ├── main.dart                    # Entry point
│   ├── app.dart                     # MaterialApp + Router setup
│   ├── config/
│   │   ├── app_config.dart          # API URL, MQTT URL, dll
│   │   ├── router.dart              # GoRouter routes
│   │   └── theme.dart               # App theme (dark + light)
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart      # Dio HTTP client dengan interceptor
│   │   │   └── api_endpoints.dart   # Konstanta semua endpoint
│   │   ├── auth/
│   │   │   ├── auth_storage.dart    # Simpan/ambil token dari SecureStorage
│   │   │   └── auth_interceptor.dart # Auto-refresh token expired
│   │   ├── mqtt/
│   │   │   ├── mqtt_client.dart     # Koneksi + subscribe MQTT
│   │   │   └── mqtt_topics.dart     # Konstanta topic MQTT
│   │   └── livekit/
│   │       └── livekit_service.dart # Wrapper livekit_client
│   ├── features/
│   │   ├── auth/
│   │   │   ├── models/
│   │   │   │   └── user.dart
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   └── screens/
│   │   │       ├── login_screen.dart
│   │   │       ├── register_screen.dart
│   │   │       └── splash_screen.dart
│   │   ├── channels/
│   │   │   ├── models/
│   │   │   │   ├── channel.dart
│   │   │   │   └── channel_member.dart
│   │   │   ├── providers/
│   │   │   │   ├── channels_provider.dart
│   │   │   │   └── channel_members_provider.dart
│   │   │   └── screens/
│   │   │       ├── channel_list_screen.dart
│   │   │       └── channel_detail_screen.dart  # Layar PTT utama
│   │   ├── ptt/
│   │   │   ├── providers/
│   │   │   │   └── ptt_provider.dart           # State PTT (transmitting, dll)
│   │   │   └── widgets/
│   │   │       ├── ptt_button.dart              # Tombol PTT (hold to talk)
│   │   │       ├── ptt_indicator.dart           # Siapa yang sedang transmit
│   │   │       └── volume_meter.dart            # Level audio
│   │   ├── map/
│   │   │   ├── providers/
│   │   │   │   └── location_provider.dart
│   │   │   └── screens/
│   │   │       └── map_screen.dart              # Peta anggota
│   │   ├── settings/
│   │   │   └── screens/
│   │   │       ├── settings_screen.dart
│   │   │       ├── audio_settings_screen.dart
│   │   │       └── bluetooth_settings_screen.dart
│   │   └── profile/
│   │       └── screens/
│   │           └── profile_screen.dart
│   └── shared/
│       ├── widgets/
│       │   ├── app_bar.dart
│       │   ├── loading_indicator.dart
│       │   ├── error_widget.dart
│       │   └── signal_strength.dart    # Indikator sinyal + baterai
│       └── utils/
│           ├── audio_utils.dart
│           └── format_utils.dart
└── test/
    ├── auth_test.dart
    ├── ptt_provider_test.dart
    └── channel_test.dart
```

---

## AndroidManifest.xml — Permissions

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- ─── Permissions Wajib ─── -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

    <!-- ─── Permissions Opsional ─── -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <application ...>
        <activity android:name=".MainActivity" ... />

        <!-- Foreground service agar PTT tetap jalan saat app di background -->
        <service
            android:name=".PttForegroundService"
            android:foregroundServiceType="microphone"
            android:exported="false" />
    </application>
</manifest>
```

---

## State Management Architecture (Riverpod)

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

PttProvider (inti dari semua)
  ├── isTransmitting: bool          → Apakah SAYA sedang transmit
  ├── currentSpeaker: Member?       → Siapa yang sedang transmit di channel
  ├── room: Room?                   → LiveKit Room object
  ├── participants: List<Participant>
  ├── startTransmit()               → Publish mic, lock PTT
  ├── stopTransmit()                → Unpublish mic, release lock
  └── muteAudio(bool)               → Mute/unmute incoming audio

LocationProvider
  ├── currentPosition: Position?
  ├── isSharing: bool
  ├── memberLocations: Map<userId, Position>
  ├── startSharing()
  └── stopSharing()

MqttProvider
  ├── isConnected: bool
  ├── connect(token)
  ├── subscribe(topic)
  └── publish(topic, message)

SettingsProvider
  ├── micGain: double (0.5 - 2.0)
  ├── speakerGain: double
  ├── voxEnabled: bool
  ├── voxThreshold: int
  ├── bluetoothDeviceId: String?
  ├── theme: ThemeMode
  └── saveSettings()
```

---

## Layar PTT Utama — channel_detail_screen.dart

Ini adalah layar paling penting. Layout:

```
┌─────────────────────────────────┐
│ ← Channel Name          🔇 ⚙️  │  ← AppBar
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐  │
│  │  [Foto] JZ12ABC           │  │  ← Siapa yang transmit sekarang
│  │  "JZ12ABC is transmitting"│  │     (animasi ring hijau)
│  └───────────────────────────┘  │
│                                 │
│  ─── Members Online (12) ────   │
│  [JZ11] [JZ22] [JZ33] [JZ44]   │  ← Avatar grid
│  [JZ55] [JZ66] [JZ77] ...      │
│                                 │
│  Signal: ████░ 4G  🔋 87%      │  ← Status bar
│                                 │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │       [  PTT  ]           │  │  ← Tombol besar, hold-to-talk
│  │   Hold to Transmit        │  │     atau toggle mode
│  │                           │  │
│  └───────────────────────────┘  │
│  VOX: OFF    Bluetooth: ON      │  ← Toggle VOX & Bluetooth
└─────────────────────────────────┘
```

---

## Implementasi PTT Button

```dart
// lib/features/ptt/widgets/ptt_button.dart

class PttButton extends ConsumerStatefulWidget {
  const PttButton({super.key});

  @override
  ConsumerState<PttButton> createState() => _PttButtonState();
}

class _PttButtonState extends ConsumerState<PttButton> {
  
  @override
  Widget build(BuildContext context) {
    final pttState = ref.watch(pttProvider);
    
    return GestureDetector(
      // Hold to talk
      onLongPressStart: (_) => ref.read(pttProvider.notifier).startTransmit(),
      onLongPressEnd: (_) => ref.read(pttProvider.notifier).stopTransmit(),
      
      // Toggle mode (ketuk 2x untuk lock transmit)
      onDoubleTap: () => ref.read(pttProvider.notifier).toggleTransmit(),
      
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pttState.isTransmitting 
              ? Colors.red 
              : Theme.of(context).colorScheme.primary,
          boxShadow: pttState.isTransmitting ? [
            BoxShadow(
              color: Colors.red.withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 10,
            ),
          ] : [],
        ),
        child: Icon(
          pttState.isTransmitting ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }
}
```

---

## Implementasi LiveKit Service

```dart
// lib/core/livekit/livekit_service.dart

class LiveKitService {
  Room? _room;
  LocalAudioTrack? _audioTrack;

  Future<void> connect({
    required String url,
    required String token,
    required String channelId,
  }) async {
    _room = Room();

    // Setup event listeners
    _room!.addListener(_onRoomEvent);

    // Connect dengan opsi audio optimized untuk PTT
    await _room!.connect(
      url,
      token,
      roomOptions: RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        audioTrackPublishDefaults: AudioTrackPublishOptions(
          audioBitrate: 32000,      // 32kbps cukup untuk voice
          dtx: true,                // Discontinuous transmission (hemat bandwidth)
        ),
      ),
    );
  }

  Future<void> startTransmit() async {
    // Request mic permission jika belum
    final status = await Permission.microphone.request();
    if (!status.isGranted) throw Exception('Microphone permission denied');

    // Buat audio track
    _audioTrack = await LocalAudioTrack.create(
      AudioCaptureOptions(
        noiseSuppression: true,
        echoCancellation: true,
        autoGainControl: true,
      ),
    );

    // Publish ke room (mulai transmit)
    await _room!.localParticipant?.publishAudioTrack(_audioTrack!);
    
    // Kirim data PTT_START ke semua participant
    await _room!.localParticipant?.publishData(
      utf8.encode(jsonEncode({'type': 'PTT_START'})),
      reliable: true,
    );
  }

  Future<void> stopTransmit() async {
    if (_audioTrack != null) {
      await _room!.localParticipant?.unpublishTrack(_audioTrack!);
      await _audioTrack!.stop();
      _audioTrack = null;
    }

    await _room!.localParticipant?.publishData(
      utf8.encode(jsonEncode({'type': 'PTT_END'})),
      reliable: true,
    );
  }

  void _onRoomEvent() {
    // Handle room events: participant join/leave, track publish, dll
  }

  Future<void> disconnect() async {
    await stopTransmit();
    await _room?.disconnect();
    _room = null;
  }
}
```

---

## Bluetooth PTT Button Support

```dart
// lib/features/settings/bluetooth_ptt_manager.dart

class BluetoothPttManager {
  // Support untuk tombol PTT eksternal via Bluetooth
  // (Tombol Tomsis, headset Bluetooth, dll)
  
  // Cara kerja:
  // 1. Scan Bluetooth devices
  // 2. Connect ke device yang dipilih user
  // 3. Listen untuk keypress events
  // 4. Map keypress ke PTT start/stop

  static const int PTT_KEY_CODE = 0x79;  // Kode umum tombol PTT HT

  void startListening(String deviceId, {
    required VoidCallback onPttStart,
    required VoidCallback onPttEnd,
  }) {
    // Implementation menggunakan flutter_bluetooth_serial
    // atau HID device listener untuk perangkat yang support
  }
}
```

---

## VOX (Voice-Activated Transmission)

```dart
// lib/features/ptt/vox_detector.dart

class VoxDetector {
  // Deteksi suara dan auto-trigger PTT
  
  int threshold;        // Level dB minimal (default: -40dB)
  int holdTimeMs;       // Tahan PTT berapa ms setelah suara stop (default: 500ms)
  
  StreamSubscription? _audioLevelSub;
  Timer? _holdTimer;
  
  void start({
    required int threshold,
    required VoidCallback onActivate,
    required VoidCallback onDeactivate,
  }) {
    // Monitor audio level dari mikrofon
    // Jika level > threshold → trigger PTT start
    // Jika level < threshold selama holdTimeMs → trigger PTT end
  }
}
```

---

## MQTT Integration

```dart
// lib/core/mqtt/mqtt_client.dart

class AppMqttClient {
  MqttServerClient? _client;

  Future<void> connect(String token) async {
    _client = MqttServerClient.withPort(
      AppConfig.mqttHost,
      'mobile-${DateTime.now().millisecondsSinceEpoch}',
      AppConfig.mqttPort,
    );
    
    _client!.secure = true;
    _client!.securityContext = SecurityContext.defaultContext;

    await _client!.connect(AppConfig.mqttUsername, token);

    // Subscribe ke topic channel yang sedang aktif
  }

  void subscribeToChannel(String channelId) {
    _client!.subscribe('poc/channels/$channelId/ptt', MqttQos.atLeastOnce);
    _client!.subscribe('poc/channels/$channelId/members', MqttQos.atLeastOnce);
    
    _client!.updates!.listen((messages) {
      for (final msg in messages) {
        final topic = msg.topic;
        final payload = jsonDecode(
          MqttPublishPayload.bytesToStringAsString(msg.payload.message)
        );
        _handleMqttMessage(topic, payload);
      }
    });
  }

  void _handleMqttMessage(String topic, Map payload) {
    if (topic.contains('/ptt')) {
      // Update UI: siapa yang sedang transmit
    } else if (topic.contains('/members')) {
      // Update daftar member online
    }
  }
}
```

---

## App Configuration

```dart
// lib/config/app_config.dart

class AppConfig {
  // Ganti untuk development vs production
  
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.yourdomain.com',
  );
  
  static const String livekitUrl = String.fromEnvironment(
    'LIVEKIT_URL', 
    defaultValue: 'wss://livekit.yourdomain.com',
  );
  
  static const String mqttHost = String.fromEnvironment(
    'MQTT_HOST',
    defaultValue: 'mqtt.yourdomain.com',
  );
  
  static const int mqttPort = int.fromEnvironment(
    'MQTT_PORT',
    defaultValue: 8883,
  );

  // PTT Config
  static const int pttMaxDurationSeconds = 60;
  static const int voxDefaultThresholdDb = -40;
  static const int voxHoldTimeMs = 500;
}
```

---

## Build untuk Production

### Android APK/AAB

```bash
# Development APK
flutter build apk --debug

# Release APK (untuk distribusi langsung)
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com \
  --dart-define=LIVEKIT_URL=wss://livekit.yourdomain.com \
  --dart-define=MQTT_HOST=mqtt.yourdomain.com

# Android App Bundle (untuk Google Play Store)
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com \
  --dart-define=LIVEKIT_URL=wss://livekit.yourdomain.com \
  --dart-define=MQTT_HOST=mqtt.yourdomain.com
```

### Signing APK untuk Release

```bash
# 1. Buat keystore (sekali saja)
keytool -genkey -v -keystore poc-pecek.keystore \
  -alias poc-pecek -keyalg RSA -keysize 2048 -validity 10000

# 2. Buat android/key.properties
# storePassword=YOUR_STORE_PASSWORD
# keyPassword=YOUR_KEY_PASSWORD
# keyAlias=poc-pecek
# storeFile=../poc-pecek.keystore

# 3. Update android/app/build.gradle untuk signing
# (tambahkan signingConfigs block)
```

### android/app/build.gradle

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.yourcompany.pocpecek"
        minSdkVersion 21    // Android 5.0+
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    // Signing untuk release
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

---

## Perintah Development

```bash
# Install dependencies
flutter pub get

# Generate kode (Riverpod, dll)
dart run build_runner build --delete-conflicting-outputs

# Run di emulator/device
flutter run

# Run dengan custom API URL (development lokal)
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:3000

# Cek masalah
flutter doctor
flutter analyze

# Test
flutter test

# Build release APK
flutter build apk --release
```

---

## Checklist Sebelum Production

- [ ] API URL sudah pointing ke server production
- [ ] LiveKit URL sudah WSS (bukan WS)
- [ ] MQTT menggunakan TLS (port 8883)
- [ ] APK sudah di-sign dengan keystore yang proper
- [ ] Semua permission di AndroidManifest.xml sudah benar
- [ ] Foreground service sudah diimplementasi (PTT tetap jalan di background)
- [ ] Test di beberapa device Android (minimal Samsung, Xiaomi, Oppo)
- [ ] Test di kondisi jaringan lemah (3G, edge)
- [ ] Test Bluetooth PTT button
- [ ] Test VOX
- [ ] Battery optimization exception sudah diminta ke user
- [ ] Crash reporting sudah dipasang (Firebase Crashlytics)
