class RouteNames {
  RouteNames._();

  static const String login = 'login';
  static const String register = 'register';
  static const String steamAuth = 'steam-auth';
  static const String discordAuth = 'discord-auth';
  static const String home = 'home';
  static const String discover = 'discover';
  static const String profile = 'profile';
  static const String createGroup = 'create-group';
  static const String groupDetail = 'group-detail';
  static const String groupCoordination = 'group-coordination';
  static const String joinGroup = 'join-group';
  static const String groupSettings = 'group-settings';
  static const String onboarding = 'onboarding';
}

class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String register = '/register';
  static const String steamAuth = '/steam-auth';
  static const String discordAuth = '/discord-auth';
  static const String home = '/';
  static const String discover = '/discover';
  static const String profile = '/profile';
  static const String createGroup = '/groups/create';
  static const String groupDetail = '/groups/:id';
  static const String groupCoordination = '/groups/:id/coordination';
  static const String joinGroup = '/join/:code';
  static const String legacyJoinGroup = '/groups/join/:code';
  static const String groupSettings = '/groups/:id/settings';
  static const String onboarding = '/onboarding';
}
