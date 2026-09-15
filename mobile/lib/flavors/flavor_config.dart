enum AppFlavor { pocPecek, hytera, ksun }

class FlavorConfig {
  static const String _flavorName = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'pocPecek',
  );

  static AppFlavor get current {
    switch (_flavorName) {
      case 'hytera':
        return AppFlavor.hytera;
      case 'ksun':
        return AppFlavor.ksun;
      default:
        return AppFlavor.pocPecek;
    }
  }

  static bool get isHytera => current == AppFlavor.hytera;
  static bool get isPocPecek => current == AppFlavor.pocPecek;
  static bool get isKsun => current == AppFlavor.ksun;

  static String get appName => 'POC-SMART';
}
