import 'permission_service.dart';

class BatteryOptimizationService {
  static Future<bool> isIgnoringBatteryOptimizations() async {
    return PermissionService.isIgnoringBatteryOptimizations();
  }

  static Future<bool> requestIgnoreBatteryOptimizations() async {
    return PermissionService.requestIgnoreBatteryOptimizations();
  }
}
