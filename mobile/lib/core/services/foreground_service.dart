import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../flavors/flavor_config.dart';

class PttForegroundService {
  static bool _initialized = false;

  static String get _appName => FlavorConfig.appName;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final isHytera = FlavorConfig.isHytera;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'ptt_foreground',
        channelName: 'PTT Active',
        channelDescription: '$_appName push-to-talk is active',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: isHytera,
        autoRunOnMyPackageReplaced: isHytera,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start(String channelName) async {
    await init();
    await FlutterForegroundTask.startService(
      notificationTitle: _appName,
      notificationText: 'Connected to $channelName',
      callback: _startCallback,
    );
  }

  static Future<void> updateNotification(String text) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: _appName,
      notificationText: text,
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_PttTaskHandler());
}

class _PttTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
