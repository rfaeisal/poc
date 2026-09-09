import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../config/app_config.dart';

class MqttService {
  MqttServerClient? _client;
  final _messageController = StreamController<MqttMessageEvent>.broadcast();
  final _connectionController = StreamController<MqttConnectionState>.broadcast();
  final Set<String> _subscribedTopics = {};

  Stream<MqttMessageEvent> get messages => _messageController.stream;
  Stream<MqttConnectionState> get connectionState => _connectionController.stream;
  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect({required String clientId}) async {
    if (AppConfig.mqttUseWebSocket) {
      _client = MqttServerClient.withPort(
        AppConfig.mqttWsUrl,
        clientId,
        443,
      )..useWebSocket = true;
    } else {
      _client = MqttServerClient(AppConfig.mqttHost, clientId)
        ..port = AppConfig.mqttPort;
    }

    _client!
      ..keepAlivePeriod = 30
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..onAutoReconnect = _onAutoReconnect
      ..onAutoReconnected = _onAutoReconnected
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..logging(on: false);

    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    try {
      await _client!.connect();
    } on Exception {
      _client?.disconnect();
      rethrow;
    }

    _client!.updates?.listen(_onMessage);
  }

  void subscribe(String topic) {
    if (_client == null || !isConnected) return;
    _client!.subscribe(topic, MqttQos.atLeastOnce);
    _subscribedTopics.add(topic);
  }

  void unsubscribe(String topic) {
    if (_client == null || !isConnected) return;
    _client!.unsubscribe(topic);
    _subscribedTopics.remove(topic);
  }

  void publish(String topic, Map<String, dynamic> payload) {
    if (_client == null || !isConnected) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));

    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void unsubscribeAll() {
    for (final topic in [..._subscribedTopics]) {
      unsubscribe(topic);
    }
  }

  Future<void> disconnect() async {
    unsubscribeAll();
    _client?.disconnect();
    _client = null;
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      final payload = msg.payload as MqttPublishMessage;
      final text = MqttPublishPayload.bytesToStringAsString(
          payload.payload.message);

      try {
        final data = jsonDecode(text) as Map<String, dynamic>;
        _messageController.add(MqttMessageEvent(
          topic: msg.topic,
          payload: data,
        ));
      } catch (_) {}
    }
  }

  void _onConnected() {
    _connectionController.add(MqttConnectionState.connected);
  }

  void _onDisconnected() {
    _connectionController.add(MqttConnectionState.disconnected);
  }

  void _onAutoReconnect() {
    _connectionController.add(MqttConnectionState.connecting);
  }

  void _onAutoReconnected() {
    _connectionController.add(MqttConnectionState.connected);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}

class MqttMessageEvent {
  final String topic;
  final Map<String, dynamic> payload;

  const MqttMessageEvent({required this.topic, required this.payload});
}
