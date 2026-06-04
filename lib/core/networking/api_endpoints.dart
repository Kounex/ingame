class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'INGAME_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
  static const String webAppBaseUrl = String.fromEnvironment(
    'INGAME_WEB_APP_BASE_URL',
    defaultValue: 'https://app.in-game.app',
  );
  static const String inviteBaseUrl = String.fromEnvironment(
    'INGAME_INVITE_BASE_URL',
    defaultValue: 'https://in-game.app',
  );

  static String get websocketUrl {
    final uri = Uri.parse(baseUrl);
    final normalizedPath = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: scheme, path: '$normalizedPath/ws').toString();
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String checkEmail = '/auth/check-email';
  static const String checkDisplayName = '/auth/check-display-name';
  static const String steamAuth = '/auth/steam';
  static const String appleAuth = '/auth/apple';

  // Users
  static const String usersMe = '/users/me';
  static const String avatarUploadInit = '/users/me/avatar-upload/init';
  static const String linkSteam = '/users/me/link-steam';
  static const String linkApple = '/users/me/link-apple';
  static const String setEmailPassword = '/users/me/set-email-password';
  static String user(String id) => '/users/$id';

  // Groups
  static const String groups = '/groups';
  static String group(String id) => '/groups/$id';
  static String groupMembers(String id) => '/groups/$id/members';
  static String groupMemberRole(String groupId, String userId) =>
      '/groups/$groupId/members/$userId/role';
  static String transferGroupOwnership(String groupId) =>
      '/groups/$groupId/transfer-ownership';
  static String leaveGroup(String groupId) => '/groups/$groupId/leave';
  static String previewJoinByCode(String code) => '/groups/join/$code';
  static String joinByCode(String code) => '/groups/join/$code';
  static const String discoverGroups = '/groups/discover';

  // Join Requests
  static String groupJoinRequests(String groupId) =>
      '/groups/$groupId/join-requests';
  static String joinRequest(String id) => '/join-requests/$id';
}
