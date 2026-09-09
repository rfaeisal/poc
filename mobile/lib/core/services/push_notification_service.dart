import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_endpoints.dart';
import '../firebase/firebase_guard.dart';
import 'device_info_service.dart';

final pushNotificationServiceProvider =
    Provider.autoDispose<PushNotificationService>((ref) {
  return PushNotificationService();
});

class PushNotificationService {
  Dio? _dio;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  String? _registeredDeviceId;

  void setDio(Dio dio) => _dio = dio;

  Future<void> initialize() async {
    if (!FirebaseGuard.isInitialized) return;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      debugPrint('Push notification permission denied');
      return;
    }

    final token = await messaging.getToken();
    if (token != null) {
      await _registerDevice(token);
    }

    _tokenRefreshSub = messaging.onTokenRefresh.listen(_registerDevice);

    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message: ${message.notification?.title}');
    });
  }

  Future<void> _registerDevice(String fcmToken) async {
    if (_dio == null) return;

    try {
      final deviceInfo = await DeviceInfoService.getDeviceInfo();
      _registeredDeviceId = deviceInfo.deviceId;

      await _dio!.post(ApiEndpoints.devices, data: {
        'deviceId': deviceInfo.deviceId,
        'fcmToken': fcmToken,
        'platform': deviceInfo.platform,
        'appVersion': deviceInfo.appVersion,
      });
      debugPrint('Device registered for push notifications');
    } catch (e) {
      debugPrint('Failed to register device: $e');
    }
  }

  Future<void> unregisterDevice() async {
    if (_dio == null || _registeredDeviceId == null) return;
    if (!FirebaseGuard.isInitialized) return;

    try {
      await _dio!.delete(ApiEndpoints.deviceById(_registeredDeviceId!));
      _registeredDeviceId = null;
      debugPrint('Device unregistered from push notifications');
    } catch (e) {
      debugPrint('Failed to unregister device: $e');
    }
  }

  Future<String?> getToken() async {
    if (!FirebaseGuard.isInitialized) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
  }
}
