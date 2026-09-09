class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const String livekitUrl = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'ws://10.0.2.2:7880',
  );

  static const String mqttHost = String.fromEnvironment(
    'MQTT_HOST',
    defaultValue: '10.0.2.2',
  );

  static const int mqttPort = int.fromEnvironment(
    'MQTT_PORT',
    defaultValue: 1883,
  );

  static const Duration accessTokenExpiry = Duration(minutes: 15);
  static const Duration pttTimeout = Duration(seconds: 60);
  static const int audioBitrate = 32000;
}
