import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:just_audio/just_audio.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/app_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

final echoTestProvider =
    StateNotifierProvider.autoDispose<EchoTestNotifier, EchoTestState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EchoTestNotifier(apiClient: apiClient);
});

enum EchoTestStatus { idle, connecting, ready, transmitting, playing, error }

class EchoTestState {
  final EchoTestStatus status;
  final int? latencyMs;
  final List<int> latencyHistory;
  final String? error;
  final Duration? transmitDuration;
  final Duration? playbackDuration;

  const EchoTestState({
    this.status = EchoTestStatus.idle,
    this.latencyMs,
    this.latencyHistory = const [],
    this.error,
    this.transmitDuration,
    this.playbackDuration,
  });

  double? get averageLatency {
    if (latencyHistory.isEmpty) return null;
    return latencyHistory.reduce((a, b) => a + b) / latencyHistory.length;
  }

  EchoTestState copyWith({
    EchoTestStatus? status,
    int? latencyMs,
    List<int>? latencyHistory,
    String? error,
    Duration? transmitDuration,
    Duration? playbackDuration,
  }) =>
      EchoTestState(
        status: status ?? this.status,
        latencyMs: latencyMs ?? this.latencyMs,
        latencyHistory: latencyHistory ?? this.latencyHistory,
        error: error,
        transmitDuration: transmitDuration ?? this.transmitDuration,
        playbackDuration: playbackDuration ?? this.playbackDuration,
      );
}

class EchoTestNotifier extends StateNotifier<EchoTestState> {
  final ApiClient _apiClient;
  Room? _pubRoom;
  Room? _subRoom;
  LocalAudioTrack? _audioTrack;
  EventsListener<RoomEvent>? _subListener;
  int? _pttStartTimestamp;
  DateTime? _transmitStart;
  webrtc.MediaRecorder? _recorder;
  AudioPlayer? _player;
  String? _recordingPath;
  StreamSubscription? _playerSub;
  StreamSubscription? _positionSub;

  EchoTestNotifier({required this._apiClient}) : super(const EchoTestState());

  Future<void> start() async {
    state = state.copyWith(
      status: EchoTestStatus.connecting,
      latencyMs: null,
      latencyHistory: [],
      error: null,
    );

    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        state = state.copyWith(
          status: EchoTestStatus.error,
          error: 'Izin mikrofon diperlukan untuk echo test',
        );
        return;
      }

      final response =
          await _apiClient.dio.post(ApiEndpoints.echoStart, data: {});
      final data = response.data;
      final publishToken = data['publishToken'] as String;
      final subscribeToken = data['subscribeToken'] as String;
      final livekitUrl = AppConfig.livekitUrl;

      _pubRoom = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(
            encoding: AudioEncoding(maxBitrate: AppConfig.audioBitrate),
            dtx: false,
          ),
          defaultAudioCaptureOptions: AudioCaptureOptions(
            echoCancellation: false,
            noiseSuppression: true,
            autoGainControl: true,
          ),
        ),
      );
      await _pubRoom!.connect(livekitUrl, publishToken);

      _subRoom = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioOutputOptions:
              AudioOutputOptions(speakerOn: false),
        ),
      );
      await _subRoom!.connect(
        livekitUrl,
        subscribeToken,
        connectOptions: const ConnectOptions(autoSubscribe: false),
      );

      _setupSubscriberListener();

      state = state.copyWith(status: EchoTestStatus.ready);
    } catch (e) {
      state = state.copyWith(
        status: EchoTestStatus.error,
        error: 'Gagal memulai echo test: $e',
      );
    }
  }

  void _setupSubscriberListener() {
    if (_subRoom == null) return;

    _subListener = _subRoom!.createListener();

    _subListener!.on<TrackPublishedEvent>((event) {
      if (_pttStartTimestamp != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final latency = now - _pttStartTimestamp!;
        final history = [...state.latencyHistory, latency];
        if (history.length > 30) {
          history.removeRange(0, history.length - 30);
        }
        state = state.copyWith(
          latencyMs: latency,
          latencyHistory: history,
        );
      }
    });
  }

  Future<void> startTransmit() async {
    if (_pubRoom == null) return;
    if (state.status != EchoTestStatus.ready) {
      return;
    }

    _pttStartTimestamp = DateTime.now().millisecondsSinceEpoch;
    _transmitStart = DateTime.now();

    _audioTrack = await LocalAudioTrack.create(
      const AudioCaptureOptions(
        echoCancellation: false,
        noiseSuppression: true,
        autoGainControl: true,
      ),
    );
    await _pubRoom!.localParticipant?.publishAudioTrack(_audioTrack!);

    try {
      _recordingPath =
          '${Directory.systemTemp.path}/echo_${DateTime.now().millisecondsSinceEpoch}.wav';
      _recorder = webrtc.MediaRecorder();
      await _recorder!.start(
        _recordingPath!,
        audioChannel: webrtc.RecorderAudioChannel.INPUT,
      );
    } catch (_) {
      _recorder = null;
      _recordingPath = null;
    }

    state = state.copyWith(status: EchoTestStatus.transmitting);
  }

  Future<void> stopTransmit() async {
    if (state.status != EchoTestStatus.transmitting) return;

    final txDuration = _transmitStart != null
        ? DateTime.now().difference(_transmitStart!)
        : null;

    try {
      await _recorder?.stop();
    } catch (_) {}
    _recorder = null;

    if (_audioTrack != null) {
      final sid = _audioTrack!.sid;
      if (sid != null) {
        await _pubRoom?.localParticipant?.removePublishedTrack(sid);
      }
      await _audioTrack?.dispose();
      _audioTrack = null;
    }

    if (_recordingPath != null && File(_recordingPath!).existsSync()) {
      state = state.copyWith(
        status: EchoTestStatus.playing,
        transmitDuration: txDuration,
        playbackDuration: Duration.zero,
      );
      try {
        await AudioManager.instance
            .setSpeakerOutputPreferred(true, force: true);

        _player = AudioPlayer(
          audioPipeline: AudioPipeline(
            androidAudioEffects: [
              AndroidLoudnessEnhancer()..setTargetGain(0.5),
            ],
          ),
        );
        final fileDuration = await _player!.setFilePath(_recordingPath!);
        if (fileDuration != null) {
          state = state.copyWith(playbackDuration: fileDuration);
        }
        await _player!.setVolume(1.0);

        _positionSub = _player!.positionStream.listen((pos) {
          if (mounted) {
            state = state.copyWith(playbackDuration: pos);
          }
        });

        _playerSub = _player!.playerStateStream.listen((playerState) {
          if (playerState.processingState == ProcessingState.completed) {
            final finalDur = _player?.duration;
            _stopPlayback();
            if (mounted) {
              state = state.copyWith(
                status: EchoTestStatus.ready,
                playbackDuration: finalDur,
              );
            }
          }
        });
        await _player!.play();
      } catch (_) {
        _stopPlayback();
        if (mounted) {
          state = state.copyWith(status: EchoTestStatus.ready);
        }
      }
    } else {
      state = state.copyWith(status: EchoTestStatus.ready);
    }
  }

  void _stopPlayback() {
    _positionSub?.cancel();
    _positionSub = null;
    _playerSub?.cancel();
    _playerSub = null;
    _player?.stop();
    _player?.dispose();
    _player = null;
    if (_recordingPath != null) {
      try {
        File(_recordingPath!).deleteSync();
      } catch (_) {}
      _recordingPath = null;
    }
  }

  Future<void> stop() async {
    _stopPlayback();

    try {
      await _recorder?.stop();
    } catch (_) {}
    _recorder = null;

    if (_audioTrack != null) {
      final sid = _audioTrack!.sid;
      if (sid != null) {
        await _pubRoom?.localParticipant?.removePublishedTrack(sid);
      }
      await _audioTrack?.dispose();
      _audioTrack = null;
    }

    _subListener?.dispose();
    _subListener = null;

    try {
      await _pubRoom?.disconnect();
    } catch (_) {}
    await _pubRoom?.dispose();
    _pubRoom = null;

    try {
      await _subRoom?.disconnect();
    } catch (_) {}
    await _subRoom?.dispose();
    _subRoom = null;

    try {
      await _apiClient.dio.post(ApiEndpoints.echoStop, data: {});
    } catch (_) {}

    state = const EchoTestState();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playerSub?.cancel();
    _player?.dispose();
    _recorder = null;
    _subListener?.dispose();
    _audioTrack?.dispose();
    _pubRoom?.dispose();
    _subRoom?.dispose();
    super.dispose();
  }
}
