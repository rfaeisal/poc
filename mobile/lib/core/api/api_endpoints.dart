class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/me';
  static const String changePassword = '/auth/change-password';

  static const String channels = '/channels';
  static String channel(String id) => '/channels/$id';
  static String joinChannel(String id) => '/channels/$id/join';
  static String leaveChannel(String id) => '/channels/$id/leave';
  static String channelMembers(String id) => '/channels/$id/members';

  static const String searchUsers = '/users/search';
  static String userProfile(String id) => '/users/$id/profile';
  static const String devices = '/users/devices';
  static String deviceById(String id) => '/users/devices/$id';

  static const String health = '/health';

  static const String echoStart = '/echo/start';
  static const String echoStop = '/echo/stop';
}
