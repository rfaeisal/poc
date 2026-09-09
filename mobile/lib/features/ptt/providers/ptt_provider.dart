import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../config/app_config.dart';
import '../../../core/livekit/livekit_service.dart';
import '../../../core/mqtt/mqtt_service.dart';
import '../../../core/mqtt/mqtt_topics.dart';
import '../../channels/models/channel.dart';
import '../../channels/providers/channel_members_provider.dart';

final livekitServiceProvider = Provider<LiveKitService>((ref) {
  final service = LiveKitService();
  ref.onDispose(() => service.disconnect());
  return service;
});

final pttProvider =
    StateNotifierProvider<PttNotifier, PttState>((ref) {
  return PttNotifier(
    livekit: ref.watch(livekitServiceProvider),
    mqtt: ref.watch(mqttServiceProvider),
  );
});

enum ConnectionStatus { disconnected, connecting, connected }

class PttState {
  final ConnectionStatus connectionStatus;
  final bool isTransmitting;
  final bool isLocked;
  final String? currentSpeakerCallsign;
  final String? currentSpeakerId;
  final String? channelName;
  final String? channelId;
  final String? error;

  const PttState({
    this.connectionStatus = ConnectionStatus.disconnected,
    this.isTransmitting = false,
    this.isLocked = false,
    this.currentSpeakerCallsign,
    this.currentSpeakerId,
    this.channelName,
    this.channelId,
    this.error,
  });

  bool get isConnected => connectionStatus == ConnectionStatus.connected;

  bool get isBusy =>
      currentSpeakerId != null && !isTransmitting;

  PttState copyWith({
    ConnectionStatus? connectionStatus,
    bool? isTransmitting,
    bool? isLocked,
    String? currentSpeakerCallsign,
    String? currentSpeakerId,
    bool clearSpeaker = false,
    String? channelName,
    String? channelId,
    String? error,
  }) =>
      PttState(
        connectionStatus: connectionStatus ?? this.connectionStatus,
        isTransmitting: isTransmitting ?? this.isTransmitting,
        isLocked: isLocked ?? this.isLocked,
        currentSpeakerCallsign:
            clearSpeaker ? null : (currentSpeakerCallsign ?? this.currentSpeakerCallsign),
        currentSpeakerId:
            clearSpeaker ? null : (currentSpeakerId ?? this.currentSpeakerId),
        channelName: channelName ?? this.channelName,
        channelId: channelId ?? this.channelId,
        error: error,
      );
}

class PttNotifier extends StateNotifier<PttState> {
  final LiveKitService _livekit;
  final MqttService _mqtt;
  Timer? _timeoutTimer;
  EventsListener<RoomEvent>? _roomListener;
  StreamSubscription<MqttMessageEvent>? _mqttPttSub;
  String? _myUserId;
  String? _myCallsign;

  PttNotifier({
    required LiveKitService livekit,
    required MqttService mqtt,
  })  : _livekit = livekit,
        _mqtt = mqtt,
        super(const PttState());

  Future<void> connect(
    JoinChannelResult result, {
    required String userId,
    required String callsign,
  }) async {
    _myUserId = userId;
    _myCallsign = callsign;

    state = state.copyWith(
      connectionStatus: ConnectionStatus.connecting,
      channelName: result.channel.name,
      channelId: result.channel.id,
    );

    try {
      await _livekit.connect(
        url: AppConfig.livekitUrl,
        token: result.livekitToken,
      );

      _setupRoomListeners();
      _setupMqttPttListener(result.channel.id);

      state = state.copyWith(connectionStatus: ConnectionStatus.connected);
    } catch (e) {
      state = state.copyWith(
        connectionStatus: ConnectionStatus.disconnected,
        error: 'Gagal connect ke channel: $e',
      );
    }
  }

  void _setupRoomListeners() {
    final room = _livekit.room;
    if (room == null) return;

    _roomListener = room.createListener();

    _roomListener!
      ..on<RoomDisconnectedEvent>((_) {
        _handleDisconnect();
      })
      ..on<RoomReconnectingEvent>((_) {
        state = state.copyWith(connectionStatus: ConnectionStatus.connecting);
      })
      ..on<RoomReconnectedEvent>((_) {
        state = state.copyWith(connectionStatus: ConnectionStatus.connected);
      });
  }

  void _setupMqttPttListener(String channelId) {
    _mqttPttSub = _mqtt.messages.listen((event) {
      if (event.topic == MqttTopics.channelPtt(channelId)) {
        _handleMqttPtt(event.payload);
      }
    });
  }

  void _handleMqttPtt(Map<String, dynamic> payload) {
    final userId = payload['userId'] as String?;
    final callsign = payload['callsign'] as String?;
    final action = payload['action'] as String?;
    if (userId == null || action == null) return;

    // Ignore own PTT events from MQTT
    if (userId == _myUserId) return;

    if (action == 'start') {
      state = state.copyWith(
        currentSpeakerId: userId,
        currentSpeakerCallsign: callsign,
      );
    } else if (action == 'end') {
      if (state.currentSpeakerId == userId) {
        state = state.copyWith(clearSpeaker: true);
      }
    }
  }

  void _handleDisconnect() {
    _timeoutTimer?.cancel();
    state = state.copyWith(
      connectionStatus: ConnectionStatus.disconnected,
      isTransmitting: false,
      isLocked: false,
      clearSpeaker: true,
    );
  }

  Future<void> startTransmit() async {
    if (state.isBusy || state.isTransmitting || !state.isConnected) return;

    await _livekit.startTransmit();
    state = state.copyWith(isTransmitting: true);

    if (state.channelId != null) {
      _mqtt.publish(MqttTopics.channelPtt(state.channelId!), {
        'userId': _myUserId,
        'callsign': _myCallsign,
        'action': 'start',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(AppConfig.pttTimeout, () {
      stopTransmit();
    });
  }

  Future<void> stopTransmit() async {
    _timeoutTimer?.cancel();
    await _livekit.stopTransmit();

    if (state.channelId != null) {
      _mqtt.publish(MqttTopics.channelPtt(state.channelId!), {
        'userId': _myUserId,
        'callsign': _myCallsign,
        'action': 'end',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    state = state.copyWith(
      isTransmitting: false,
      isLocked: false,
    );
  }

  void toggleLock() {
    if (state.isTransmitting) {
      if (state.isLocked) {
        stopTransmit();
      } else {
        state = state.copyWith(isLocked: true);
      }
    } else if (!state.isBusy) {
      startTransmit();
      state = state.copyWith(isLocked: true);
    }
  }

  Future<void> disconnect() async {
    _timeoutTimer?.cancel();
    _roomListener?.dispose();
    _roomListener = null;
    await _mqttPttSub?.cancel();
    _mqttPttSub = null;
    await _livekit.disconnect();
    state = const PttState();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _roomListener?.dispose();
    _mqttPttSub?.cancel();
    super.dispose();
  }
}
