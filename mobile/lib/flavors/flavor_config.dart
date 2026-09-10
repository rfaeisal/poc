enum AppFlavor { pocPecek, hytera }

class FlavorConfig {
  static const String _flavorName = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'pocPecek',
  );

  static AppFlavor get current {
    switch (_flavorName) {
      case 'hytera':
        return AppFlavor.hytera;
      default:
        return AppFlavor.pocPecek;
    }
  }

  static bool get isHytera => current == AppFlavor.hytera;
  static bool get isPocPecek => current == AppFlavor.pocPecek;

  static String get appName => isHytera ? 'POC-PTX' : 'POC-Pecek';
}
