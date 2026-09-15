import 'package:flutter/services.dart';

class KsunKioskService {
  static const _channel = MethodChannel('com.fakhriez.poc_ptx/kiosk');

  static Future<void> exitApp() async {
    try {
      await _channel.invokeMethod('exitApp');
    } on PlatformException catch (_) {
      SystemNavigator.pop();
    }
  }

  static Future<void> bringToFront() async {
    try {
      await _channel.invokeMethod('bringToFront');
    } on PlatformException catch (_) {}
  }

  static Future<void> keepScreenOn({bool enable = true}) async {
    try {
      await _channel.invokeMethod('keepScreenOn', {'enable': enable});
    } on PlatformException catch (_) {}
  }

  static Future<void> maxVolume() async {
    try {
      await _channel.invokeMethod('maxVolume');
    } on PlatformException catch (_) {}
  }
}
