class MqttTopics {
  static String channelPtt(String channelId) =>
      'poc/channels/$channelId/ptt';

  static String channelMembers(String channelId) =>
      'poc/channels/$channelId/members';

  static String channelStatus(String channelId) =>
      'poc/channels/$channelId/status';

  static String userPresence(String userId) =>
      'poc/users/$userId/presence';

  static String userLocation(String userId) =>
      'poc/users/$userId/location';
}
