import 'package:flutter/services.dart';

class KioskService {
  static const _channel = MethodChannel('com.fakhriez.poc_ptx/kiosk');

  static Future<void> enableKiosk() async {
    try {
      await _channel.invokeMethod('enableKiosk');
    } on PlatformException catch (_) {}
  }

  static Future<void> disableKiosk() async {
    try {
      await _channel.invokeMethod('disableKiosk');
    } on PlatformException catch (_) {}
  }

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

  static Future<void> wakeScreen() async {
    try {
      await _channel.invokeMethod('wakeScreen');
    } on PlatformException catch (_) {}
  }

  static Future<void> keepScreenOn({bool enable = true}) async {
    try {
      await _channel.invokeMethod('keepScreenOn', {'enable': enable});
    } on PlatformException catch (_) {}
  }

  static Future<void> showOnLockScreen() async {
    try {
      await _channel.invokeMethod('showOnLockScreen');
    } on PlatformException catch (_) {}
  }
}
