import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_session.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/steam_auth_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/group_detail_screen.dart';
import '../../features/groups/presentation/screens/group_settings_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import 'page_transitions.dart';
import '../../features/groups/presentation/screens/group_directory_screen.dart';
import '../../features/groups/presentation/screens/groups_list_screen.dart';
import '../../features/groups/presentation/screens/join_group_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/widgets/adaptive_shell.dart';
import 'route_names.dart';
import 'route_normalization.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Listenable that fires when auth state changes, used by GoRouter's
/// refreshListenable to re-evaluate redirects without rebuilding the router.
final _authRefreshListenableProvider = Provider<ValueNotifier<AuthState?>>((ref) {
  final notifier = ValueNotifier<AuthState?>(null);
  ref.listen(authNotifierProvider, (_, next) {
    notifier.value = next.valueOrNull;
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.home,
    refreshListenable: ref.watch(_authRefreshListenableProvider),
    redirect: (context, state) {
      final currentLocation = state.uri.toString();
      final normalizedCurrentLocation = normalizeRouteLocation(currentLocation);
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState.maybeWhen(
        data: (s) => s.maybeWhen(
          authenticated: (_) => true,
          orElse: () => false,
        ),
        orElse: () => false,
      );

      final isAuthRoute = state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register ||
          state.matchedLocation == RoutePaths.steamAuth;
      final isOnboarding = state.matchedLocation == RoutePaths.onboarding;
      final redirectTarget = sanitizeRedirectTarget(
        state.uri.queryParameters['from'],
      );

      if (!isAuthenticated && !isAuthRoute) {
        final isLogoutRedirectPending = ref.read(logoutRedirectPendingProvider);
        if (isLogoutRedirectPending) {
          ref.read(logoutRedirectPendingProvider.notifier).state = false;
          return RoutePaths.login;
        }

        final from = sanitizeRedirectTarget(currentLocation);
        return Uri(
          path: RoutePaths.login,
          queryParameters: from == null ? null : {'from': from},
        ).toString();
      }
      if (isAuthenticated && isAuthRoute) {
        return redirectTarget ?? RoutePaths.home;
      }

      if (isAuthenticated) {
        final needsOnboarding = ref.read(needsOnboardingProvider);
        if (needsOnboarding) {
          if (!isOnboarding) {
            final from = sanitizeRedirectTarget(currentLocation);
            return Uri(
              path: RoutePaths.onboarding,
              queryParameters: from == null ? null : {'from': from},
            ).toString();
          }
        } else if (isOnboarding) {
          return redirectTarget ?? RoutePaths.home;
        }
      }

      if (normalizedCurrentLocation != null &&
          normalizedCurrentLocation != currentLocation) {
        return normalizedCurrentLocation;
      }

      return null;
    },
    routes: [
      // Focused flows — no persistent navigation
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => LoginScreen(
          redirectTo: sanitizeRedirectTarget(state.uri.queryParameters['from']),
        ),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => RegisterScreen(
          redirectTo: sanitizeRedirectTarget(state.uri.queryParameters['from']),
        ),
      ),
      GoRoute(
        path: RoutePaths.steamAuth,
        name: RouteNames.steamAuth,
        builder: (context, state) => SteamAuthScreen(
          redirectTo: sanitizeRedirectTarget(state.uri.queryParameters['from']),
        ),
      ),
      GoRoute(
        path: RoutePaths.joinGroup,
        name: RouteNames.joinGroup,
        pageBuilder: (context, state) {
          final code = state.pathParameters['code']!;
          return fadeSlideTransition(
            key: state.pageKey,
            child: JoinGroupScreen(inviteCode: code),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.legacyJoinGroup,
        redirect: (_, state) =>
            '/join/${state.pathParameters['code'] ?? ''}',
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        pageBuilder: (context, state) => fadeSlideTransition(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),

      // Shell — persistent sidebar / bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdaptiveShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) => const GroupsListScreen(),
                routes: [
                  GoRoute(
                    path: 'groups/create',
                    name: RouteNames.createGroup,
                    pageBuilder: (context, state) => fadeSlideTransition(
                      key: state.pageKey,
                      child: const CreateGroupScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/:id',
                    name: RouteNames.groupDetail,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return fadeSlideTransition(
                        key: state.pageKey,
                        child: GroupDetailScreen(groupId: id),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'settings',
                        name: RouteNames.groupSettings,
                        pageBuilder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return fadeSlideTransition(
                            key: state.pageKey,
                            child: GroupSettingsScreen(groupId: id),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.discover,
                name: RouteNames.discover,
                builder: (context, state) => const GroupDirectoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: RouteNames.editProfile,
                    pageBuilder: (context, state) => fadeSlideTransition(
                      key: state.pageKey,
                      child: const EditProfileScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

@Deprecated('Use AdaptiveShell instead')
typedef ScaffoldWithNav = AdaptiveShell;
