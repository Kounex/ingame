import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ingame/core/networking/app_failure.dart';
import 'package:ingame/core/routing/route_names.dart';
import 'package:ingame/core/storage/preferences.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/auth/presentation/screens/login_screen.dart';
import 'package:ingame/features/auth/presentation/screens/register_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;
}

Future<void> _pumpAuthFlow(
  WidgetTester tester, {
  required AuthNotifier authNotifier,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: RoutePaths.login,
    routes: [
      GoRoute(path: RoutePaths.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: RoutePaths.register,
        builder: (_, _) => const RegisterScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => authNotifier),
        preferencesProvider.overrideWithValue(PreferencesService(prefs)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('switching from login to register clears stale auth banner', (
    tester,
  ) async {
    await _pumpAuthFlow(
      tester,
      authNotifier: _FakeAuthNotifier(
        const AuthState.error(
          BackendFailure(
            statusCode: 401,
            detail: 'Invalid email or password',
            code: 'auth.invalid_credentials',
          ),
        ),
      ),
    );

    expect(find.text('Invalid credentials. Please try again.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Register'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Invalid credentials. Please try again.'), findsNothing);
  });
}
