import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static int? _sdkVersion;

  static Future<int> get sdkVersion async {
    if (_sdkVersion != null) return _sdkVersion!;
    if (!Platform.isAndroid) return 99;
    final info = await DeviceInfoPlugin().androidInfo;
    _sdkVersion = info.version.sdkInt;
    return _sdkVersion!;
  }

  static Future<bool> requestMicrophone() async {
    if (await sdkVersion < 23) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    if (await sdkVersion < 23) return true;
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    if (await sdkVersion < 23) return true;
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }
}
