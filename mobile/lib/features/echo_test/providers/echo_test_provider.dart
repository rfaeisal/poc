import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../config/app_config.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

const _kioskChannel = MethodChannel('com.fakhriez.poc_ptx/kiosk');

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
  Room? _room;
  EventsListener<RoomEvent>? _roomListener;
  LocalAudioTrack? _audioTrack;
  DateTime? _transmitStart;
  int? _stopTransmitTimestamp;
  DateTime? _playbackStart;

  EchoTestNotifier({required this._apiClient}) : super(const EchoTestState());

  Future<void> start() async {
    state = state.copyWith(
      status: EchoTestStatus.connecting,
      latencyMs: null,
      latencyHistory: [],
      error: null,
    );

    try {
      final micGranted = await PermissionService.requestMicrophone();
      if (!micGranted) {
        state = state.copyWith(
          status: EchoTestStatus.error,
          error: 'Izin mikrofon diperlukan untuk echo test',
        );
        return;
      }

      final response =
          await _apiClient.dio.post(ApiEndpoints.echoStart, data: {});
      final data = response.data;
      final token = data['token'] as String;
      final livekitUrl = AppConfig.livekitUrl;

      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(
            encoding: AudioEncoding(maxBitrate: AppConfig.audioBitrate),
            dtx: false,
          ),
        ),
      );

      await _room!.connect(livekitUrl, token);
      _setupRoomListeners();

      state = state.copyWith(status: EchoTestStatus.ready);
    } catch (e) {
      state = state.copyWith(
        status: EchoTestStatus.error,
        error: 'Gagal memulai echo test: $e',
      );
    }
  }

  void _setupRoomListeners() {
    if (_room == null) return;
    _roomListener = _room!.createListener();

    _roomListener!
      ..on<TrackSubscribedEvent>((event) {
        if (event.track is AudioTrack) {
          // Bot echoing back — route audio to speaker
          try {
            _kioskChannel.invokeMethod('ensureAudioOutput');
          } catch (_) {}

          _playbackStart = DateTime.now();

          // Measure latency: time from stop TX to bot echo arriving
          if (_stopTransmitTimestamp != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final latency = now - _stopTransmitTimestamp!;
            final history = [...state.latencyHistory, latency];
            if (history.length > 30) {
              history.removeRange(0, history.length - 30);
            }
            state = state.copyWith(
              status: EchoTestStatus.playing,
              latencyMs: latency,
              latencyHistory: history,
              playbackDuration: Duration.zero,
            );
          } else {
            state = state.copyWith(
              status: EchoTestStatus.playing,
              playbackDuration: Duration.zero,
            );
          }
        }
      })
      ..on<TrackUnsubscribedEvent>((event) {
        if (event.track is AudioTrack) {
          // Bot finished playing echo
          final playDuration = _playbackStart != null
              ? DateTime.now().difference(_playbackStart!)
              : null;
          _playbackStart = null;
          if (mounted) {
            state = state.copyWith(
              status: EchoTestStatus.ready,
              playbackDuration: playDuration,
            );
          }
        }
      })
      ..on<RoomDisconnectedEvent>((_) {
        if (mounted) {
          state = state.copyWith(
            status: EchoTestStatus.error,
            error: 'Koneksi terputus',
          );
        }
      });
  }

  Future<void> startTransmit() async {
    if (_room == null) return;
    if (state.status != EchoTestStatus.ready) return;

    _transmitStart = DateTime.now();
    _stopTransmitTimestamp = null;

    _audioTrack = await LocalAudioTrack.create(
      const AudioCaptureOptions(
        noiseSuppression: true,
        echoCancellation: true,
        autoGainControl: true,
      ),
    );
    await _room!.localParticipant?.publishAudioTrack(_audioTrack!);

    state = state.copyWith(status: EchoTestStatus.transmitting);
  }

  Future<void> stopTransmit() async {
    if (state.status != EchoTestStatus.transmitting) return;

    final txDuration = _transmitStart != null
        ? DateTime.now().difference(_transmitStart!)
        : null;

    _stopTransmitTimestamp = DateTime.now().millisecondsSinceEpoch;

    // Unpublish and dispose track
    if (_audioTrack != null) {
      final sid = _audioTrack!.sid;
      if (sid != null) {
        await _room?.localParticipant?.removePublishedTrack(sid);
      }
      await _audioTrack!.dispose();
      _audioTrack = null;
    }

    // Go to ready and wait for bot echo via TrackSubscribedEvent
    state = state.copyWith(
      status: EchoTestStatus.ready,
      transmitDuration: txDuration,
    );
  }

  Future<void> stop() async {
    state = const EchoTestState();

    _roomListener?.dispose();
    _roomListener = null;

    if (_audioTrack != null) {
      final sid = _audioTrack!.sid;
      if (sid != null) {
        try {
          await _room?.localParticipant?.removePublishedTrack(sid);
        } catch (_) {}
      }
      await _audioTrack!.dispose();
      _audioTrack = null;
    }

    try {
      await _room?.disconnect();
    } catch (_) {}
    await _room?.dispose();
    _room = null;

    try {
      await _apiClient.dio.post(ApiEndpoints.echoStop, data: {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _roomListener?.dispose();
    _audioTrack?.dispose();
    _room?.dispose();
    super.dispose();
  }
}
