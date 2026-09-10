import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mqtt/mqtt_service.dart';
import '../../../core/mqtt/mqtt_topics.dart';
import '../../channels/providers/channel_members_provider.dart';
import '../models/message.dart';

class MessagingState {
  final Map<String, List<ChatMessage>> messagesByChannel;
  final String? activeChannelId;

  const MessagingState({
    this.messagesByChannel = const {},
    this.activeChannelId,
  });

  List<ChatMessage> get activeMessages =>
      activeChannelId != null
          ? (messagesByChannel[activeChannelId] ?? [])
          : [];

  MessagingState copyWith({
    Map<String, List<ChatMessage>>? messagesByChannel,
    String? activeChannelId,
  }) =>
      MessagingState(
        messagesByChannel: messagesByChannel ?? this.messagesByChannel,
        activeChannelId: activeChannelId ?? this.activeChannelId,
      );
}

class MessagingNotifier extends StateNotifier<MessagingState> {
  final MqttService _mqtt;
  final Set<String> _subscribedChannels = {};
  StreamSubscription<MqttMessageEvent>? _subscription;

  MessagingNotifier({required MqttService mqtt})
      : _mqtt = mqtt,
        super(const MessagingState()) {
    _subscription = _mqtt.messages.listen(_onMqttMessage);
  }

  void setActiveChannel(String channelId) {
    state = state.copyWith(activeChannelId: channelId);
  }

  void subscribeToChannel(String channelId) {
    if (_subscribedChannels.contains(channelId)) return;
    _subscribedChannels.add(channelId);
    _mqtt.subscribe(MqttTopics.channelMessages(channelId));
  }

  void unsubscribeFromChannel(String channelId) {
    if (!_subscribedChannels.remove(channelId)) return;
    _mqtt.unsubscribe(MqttTopics.channelMessages(channelId));
  }

  void sendMessage({
    required String channelId,
    required String content,
    required String senderId,
    required String senderCallsign,
  }) {
    final message = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderId: senderId,
      senderCallsign: senderCallsign,
      content: content,
      timestamp: DateTime.now(),
      channelId: channelId,
    );

    _addMessage(channelId, message);

    _mqtt.publish(
      MqttTopics.channelMessages(channelId),
      message.toJson(),
    );
  }

  void _onMqttMessage(MqttMessageEvent event) {
    for (final channelId in _subscribedChannels) {
      final topic = MqttTopics.channelMessages(channelId);
      if (event.topic == topic) {
        try {
          final message = ChatMessage.fromJson(event.payload);
          final isDuplicate = state.messagesByChannel[channelId]
                  ?.any((m) => m.id == message.id) ??
              false;
          if (!isDuplicate) {
            _addMessage(channelId, message);
          }
        } catch (e) {
          debugPrint('Failed to parse chat message: $e');
        }
      }
    }
  }

  void _addMessage(String channelId, ChatMessage message) {
    final updated = Map<String, List<ChatMessage>>.from(state.messagesByChannel);
    updated[channelId] = [...(updated[channelId] ?? []), message];
    state = state.copyWith(messagesByChannel: updated);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    for (final channelId in _subscribedChannels) {
      _mqtt.unsubscribe(MqttTopics.channelMessages(channelId));
    }
    _subscribedChannels.clear();
    super.dispose();
  }
}

final messagingProvider =
    StateNotifierProvider<MessagingNotifier, MessagingState>((ref) {
  return MessagingNotifier(mqtt: ref.watch(mqttServiceProvider));
});
