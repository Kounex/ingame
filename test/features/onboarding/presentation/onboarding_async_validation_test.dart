import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/storage/secure_storage.dart';
import 'package:ingame/features/auth/data/auth_repository.dart';
import 'package:ingame/features/auth/domain/auth_state.dart';
import 'package:ingame/features/auth/domain/user_model.dart';
import 'package:ingame/features/auth/presentation/providers/auth_provider.dart';
import 'package:ingame/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ingame/features/profile/presentation/providers/profile_provider.dart';
import 'package:ingame/l10n/app_localizations.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;
}

class _FakeProfileNotifier extends ProfileNotifier {
  @override
  Future<User?> build() async => null;
}

class _FakeSecureStorageService implements SecureStorageService {
  @override
  Future<void> clearTokens() async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({required this.emailAvailable})
    : super(dio: Dio(), storage: _FakeSecureStorageService());

  final bool emailAvailable;

  @override
  Future<bool> checkEmailAvailable(String email) async => emailAvailable;
}

Future<void> _pumpOnboardingScreen(
  WidgetTester tester, {
  required AuthRepository authRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(
            const AuthState.authenticated(
              User(id: 'user-1', displayName: 'Ready Player', timezone: 'UTC'),
            ),
          ),
        ),
        profileNotifierProvider.overrideWith(() => _FakeProfileNotifier()),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const OnboardingScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'onboarding shows the email availability message when debounce validation fails',
    (tester) async {
      await _pumpOnboardingScreen(
        tester,
        authRepository: _FakeAuthRepository(emailAvailable: false),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Ready Player');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'taken@example.com',
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('This email is already taken'), findsOneWidget);
    },
  );
}
