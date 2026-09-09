import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/mqtt/mqtt_service.dart';
import '../../channels/providers/channel_members_provider.dart';

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final mqtt = ref.watch(mqttServiceProvider);
  return LocationNotifier(mqtt);
});

class LocationState {
  final LatLng? myLocation;
  final Map<String, MemberLocation> memberLocations;
  final bool isSharing;

  const LocationState({
    this.myLocation,
    this.memberLocations = const {},
    this.isSharing = false,
  });

  LocationState copyWith({
    LatLng? myLocation,
    Map<String, MemberLocation>? memberLocations,
    bool? isSharing,
  }) =>
      LocationState(
        myLocation: myLocation ?? this.myLocation,
        memberLocations: memberLocations ?? this.memberLocations,
        isSharing: isSharing ?? this.isSharing,
      );
}

class MemberLocation {
  final String userId;
  final String callsign;
  final LatLng position;
  final DateTime timestamp;

  const MemberLocation({
    required this.userId,
    required this.callsign,
    required this.position,
    required this.timestamp,
  });
}

class LocationNotifier extends StateNotifier<LocationState> {
  final MqttService _mqtt;
  StreamSubscription<MqttMessageEvent>? _mqttSub;
  StreamSubscription<Position>? _positionSub;
  String? _userId;
  String? _channelId;

  LocationNotifier(this._mqtt) : super(const LocationState());

  Future<bool> _checkPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> startSharing({
    required String userId,
    required String callsign,
    required String channelId,
  }) async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) return;

    _userId = userId;
    _channelId = channelId;

    // Subscribe to location updates from other members
    _mqtt.subscribe('poc/channels/$channelId/location');
    _mqttSub = _mqtt.messages.listen((event) {
      if (event.topic == 'poc/channels/$channelId/location') {
        _handleLocationMessage(event.payload);
      }
    });

    // Start GPS tracking
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      state = state.copyWith(myLocation: latLng, isSharing: true);

      _mqtt.publish('poc/channels/$channelId/location', {
        'userId': userId,
        'callsign': callsign,
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    state = state.copyWith(isSharing: true);
  }

  void _handleLocationMessage(Map<String, dynamic> payload) {
    final userId = payload['userId'] as String?;
    if (userId == null || userId == _userId) return;

    final lat = (payload['lat'] as num?)?.toDouble();
    final lng = (payload['lng'] as num?)?.toDouble();
    final callsign = payload['callsign'] as String? ?? userId;

    if (lat == null || lng == null) return;

    final updated = Map<String, MemberLocation>.from(state.memberLocations);
    updated[userId] = MemberLocation(
      userId: userId,
      callsign: callsign,
      position: LatLng(lat, lng),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(memberLocations: updated);
  }

  Future<void> stopSharing() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _mqttSub?.cancel();
    _mqttSub = null;

    if (_channelId != null) {
      _mqtt.unsubscribe('poc/channels/$_channelId/location');
    }

    state = const LocationState();
  }

  @override
  void dispose() {
    stopSharing();
    super.dispose();
  }
}
