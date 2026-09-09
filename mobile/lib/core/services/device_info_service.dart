import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfo {
  final String deviceId;
  final String platform;
  final String model;
  final String osVersion;
  final String appVersion;
  final String appBuildNumber;

  const DeviceInfo({
    required this.deviceId,
    required this.platform,
    required this.model,
    required this.osVersion,
    required this.appVersion,
    required this.appBuildNumber,
  });
}

class DeviceInfoService {
  static DeviceInfo? _cached;

  static Future<DeviceInfo> getDeviceInfo() async {
    if (_cached != null) return _cached!;

    final deviceInfoPlugin = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String deviceId;
    String model;
    String osVersion;

    if (Platform.isAndroid) {
      final android = await deviceInfoPlugin.androidInfo;
      deviceId = android.id;
      model = '${android.manufacturer} ${android.model}';
      osVersion = 'Android ${android.version.release} (SDK ${android.version.sdkInt})';
    } else if (Platform.isIOS) {
      final ios = await deviceInfoPlugin.iosInfo;
      deviceId = ios.identifierForVendor ?? 'unknown';
      model = ios.utsname.machine;
      osVersion = '${ios.systemName} ${ios.systemVersion}';
    } else {
      deviceId = 'unknown';
      model = 'unknown';
      osVersion = Platform.operatingSystemVersion;
    }

    _cached = DeviceInfo(
      deviceId: deviceId,
      platform: Platform.isAndroid ? 'ANDROID' : 'IOS',
      model: model,
      osVersion: osVersion,
      appVersion: packageInfo.version,
      appBuildNumber: packageInfo.buildNumber,
    );

    return _cached!;
  }
}
