import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/mqtt/mqtt_service.dart';
import '../../../core/mqtt/mqtt_topics.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/channel_member.dart';

final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService();
  ref.onDispose(() => service.dispose());
  return service;
});

final channelMembersProvider =
    StateNotifierProvider<ChannelMembersNotifier, ChannelMembersState>((ref) {
  return ChannelMembersNotifier(
    dio: ref.watch(apiClientProvider).dio,
    mqtt: ref.watch(mqttServiceProvider),
  );
});

class ChannelMembersState {
  final Map<String, ChannelMember> members;
  final String? transmitterId;
  final bool isLoading;

  const ChannelMembersState({
    this.members = const {},
    this.transmitterId,
    this.isLoading = false,
  });

  List<ChannelMember> get onlineMembers =>
      members.values.where((m) => m.isOnline).toList();

  ChannelMember? get currentSpeaker =>
      transmitterId != null ? members[transmitterId] : null;

  ChannelMembersState copyWith({
    Map<String, ChannelMember>? members,
    String? transmitterId,
    bool clearTransmitter = false,
    bool? isLoading,
  }) =>
      ChannelMembersState(
        members: members ?? this.members,
        transmitterId: clearTransmitter ? null : (transmitterId ?? this.transmitterId),
        isLoading: isLoading ?? this.isLoading,
      );
}

class ChannelMembersNotifier extends StateNotifier<ChannelMembersState> {
  final Dio _dio;
  final MqttService _mqtt;
  StreamSubscription<MqttMessageEvent>? _mqttSub;
  String? _currentChannelId;

  ChannelMembersNotifier({
    required Dio dio,
    required MqttService mqtt,
  })  : _dio = dio,
        _mqtt = mqtt,
        super(const ChannelMembersState());

  Future<void> joinChannel(String channelId, {required String myUserId}) async {
    _currentChannelId = channelId;
    state = state.copyWith(isLoading: true);

    await _fetchMembers(channelId);

    if (!_mqtt.isConnected) {
      try {
        await _mqtt.connect(clientId: 'poc_pecek_$myUserId');
      } catch (_) {}
    }

    _mqtt.subscribe(MqttTopics.channelMembers(channelId));
    _mqtt.subscribe(MqttTopics.channelPtt(channelId));

    _mqttSub = _mqtt.messages.listen((event) {
      if (event.topic == MqttTopics.channelMembers(channelId)) {
        _handleMemberEvent(event.payload);
      } else if (event.topic == MqttTopics.channelPtt(channelId)) {
        _handlePttEvent(event.payload);
      }
    });

    state = state.copyWith(isLoading: false);
  }

  Future<void> _fetchMembers(String channelId) async {
    try {
      final response = await _dio.get(ApiEndpoints.channelMembers(channelId));
      final list = (response.data['members'] as List)
          .map((e) => ChannelMember.fromApiJson(e as Map<String, dynamic>))
          .toList();

      final membersMap = <String, ChannelMember>{};
      for (final m in list) {
        membersMap[m.userId] = m;
      }
      state = state.copyWith(members: membersMap);
    } on DioException catch (_) {}
  }

  void _handleMemberEvent(Map<String, dynamic> payload) {
    final userId = payload['userId'] as String?;
    final callsign = payload['callsign'] as String? ?? '???';
    final action = payload['action'] as String?;
    if (userId == null || action == null) return;

    final updated = Map<String, ChannelMember>.from(state.members);

    if (action == 'join') {
      updated[userId] = ChannelMember(
        userId: userId,
        callsign: callsign,
        isOnline: true,
      );
    } else if (action == 'leave') {
      updated.remove(userId);
    }

    state = state.copyWith(members: updated);
  }

  void _handlePttEvent(Map<String, dynamic> payload) {
    final userId = payload['userId'] as String?;
    final action = payload['action'] as String?;
    if (action == null) return;

    if (action == 'start' && userId != null) {
      final updated = Map<String, ChannelMember>.from(state.members);
      if (updated.containsKey(userId)) {
        updated[userId] = updated[userId]!.copyWith(isTransmitting: true);
      }
      state = state.copyWith(members: updated, transmitterId: userId);
    } else if (action == 'end') {
      final updated = Map<String, ChannelMember>.from(state.members);
      final prevId = state.transmitterId;
      if (prevId != null && updated.containsKey(prevId)) {
        updated[prevId] = updated[prevId]!.copyWith(isTransmitting: false);
      }
      state = state.copyWith(members: updated, clearTransmitter: true);
    }
  }

  Future<void> leaveChannel() async {
    if (_currentChannelId != null) {
      _mqtt.unsubscribe(MqttTopics.channelMembers(_currentChannelId!));
      _mqtt.unsubscribe(MqttTopics.channelPtt(_currentChannelId!));
    }
    await _mqttSub?.cancel();
    _mqttSub = null;
    _currentChannelId = null;
    state = const ChannelMembersState();
  }

  @override
  void dispose() {
    _mqttSub?.cancel();
    super.dispose();
  }
}
