import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/storage/secure_storage.dart';
import 'package:ingame/features/auth/data/auth_repository.dart';
import 'package:ingame/features/auth/presentation/screens/register_screen.dart';
import 'package:ingame/l10n/app_localizations.dart';

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
  _FakeAuthRepository({
    required this.emailAvailable,
    required this.displayNameAvailable,
  }) : super(dio: Dio(), storage: _FakeSecureStorageService());

  final bool emailAvailable;
  final bool displayNameAvailable;

  @override
  Future<bool> checkEmailAvailable(String email) async => emailAvailable;

  @override
  Future<bool> checkDisplayNameAvailable(String displayName) async =>
      displayNameAvailable;
}

class _DelayedAuthRepository extends AuthRepository {
  _DelayedAuthRepository()
    : super(dio: Dio(), storage: _FakeSecureStorageService());

  @override
  Future<bool> checkEmailAvailable(String email) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return true;
  }

  @override
  Future<bool> checkDisplayNameAvailable(String displayName) async => true;
}

Future<void> _pumpRegisterScreen(
  WidgetTester tester, {
  required AuthRepository authRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
      child: const MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: RegisterScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'register shows the display name availability message when debounce validation fails',
    (tester) async {
      await _pumpRegisterScreen(
        tester,
        authRepository: _FakeAuthRepository(
          emailAvailable: true,
          displayNameAvailable: false,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Taken Name');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('This display name is already taken'), findsOneWidget);
    },
  );

  testWidgets('register renders a compact email availability spinner', (
    tester,
  ) async {
    await _pumpRegisterScreen(tester, authRepository: _DelayedAuthRepository());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'ready@test.com');
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.getSize(find.byType(CircularProgressIndicator)),
      const Size(16, 16),
    );
  });

  testWidgets('register renders a compact aligned availability error icon', (
    tester,
  ) async {
    await _pumpRegisterScreen(
      tester,
      authRepository: _FakeAuthRepository(
        emailAvailable: false,
        displayNameAvailable: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'taken@test.com');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.cancel_outlined));
    expect(icon.size, 16);

    final padding = tester.widget<Padding>(
      find
          .ancestor(
            of: find.byIcon(Icons.cancel_outlined),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(padding.padding, const EdgeInsetsDirectional.only(end: 12));
  });

  testWidgets('register keeps the primary action compact on desktop', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpRegisterScreen(
      tester,
      authRepository: _FakeAuthRepository(
        emailAvailable: true,
        displayNameAvailable: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.widgetWithText(ElevatedButton, 'Create Account'))
          .width,
      lessThan(600),
    );
  });
}
