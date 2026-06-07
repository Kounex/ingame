import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:line_icons/line_icons.dart';

import 'package:ingame/features/auth/presentation/widgets/social_login_buttons.dart';
import 'package:ingame/l10n/app_localizations.dart';
import 'package:ingame/shared/widgets/provider_visuals.dart';

class _Harness extends StatelessWidget {
  const _Harness({
    required this.child,
    required this.locale,
    this.textScaler = TextScaler.noScaling,
  });

  final Widget child;
  final Locale locale;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return Cue.onMount(
      acts: const [],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, appChild) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: appChild!,
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }
}

void _noop() {}

BoxDecoration _buttonDecoration(WidgetTester tester, String label) {
  return tester
          .widget<DecoratedBox>(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration
      as BoxDecoration;
}

void main() {
  testWidgets('social login buttons expose button semantics', (tester) async {
    await tester.pumpWidget(
      const _Harness(
        locale: Locale('en'),
        child: SocialLoginButtons(onSteamPressed: _noop),
      ),
    );

    expect(
      tester.getSemantics(find.text('Continue with Steam')),
      matchesSemantics(
        label: 'Continue with Steam',
        hasTapAction: true,
        hasFocusAction: true,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
      ),
    );
  });

  testWidgets('social login buttons use line icon branding for Steam', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        locale: Locale('en'),
        child: SocialLoginButtons(onSteamPressed: null),
      ),
    );

    expect(find.text('Continue with Steam'), findsOneWidget);
    expect(find.byIcon(LineIcons.steam), findsOneWidget);
    final decoration = _buttonDecoration(tester, 'Continue with Steam');
    expect(
      decoration.gradient,
      isA<LinearGradient>()
          .having(
            (gradient) => gradient.colors.first,
            'start',
            ProviderVisuals.steamMid,
          )
          .having(
            (gradient) => gradient.colors.last,
            'end',
            ProviderVisuals.steamNavy,
          ),
    );
    expect(decoration.border?.top.color, ProviderVisuals.steamBlue);
  });

  testWidgets('social login buttons use line icon branding for Discord', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        locale: Locale('en'),
        child: SocialLoginButtons(showDiscord: true, onDiscordPressed: null),
      ),
    );

    expect(find.text('Continue with Discord'), findsOneWidget);
    expect(find.byIcon(LineIcons.discord), findsOneWidget);
    final decoration = _buttonDecoration(tester, 'Continue with Discord');
    expect(
      decoration.gradient,
      isA<LinearGradient>()
          .having(
            (gradient) => gradient.colors.first,
            'start',
            ProviderVisuals.discordPrimary,
          )
          .having(
            (gradient) => gradient.colors.last,
            'end',
            ProviderVisuals.discordSecondary,
          ),
    );
    expect(
      tester.widget<Icon>(find.byIcon(LineIcons.discord)).color,
      Colors.white,
    );
  });

  testWidgets(
    'social login buttons use line icon branding for Apple on iOS',
    (tester) async {
      await tester.pumpWidget(
        const _Harness(
          locale: Locale('en'),
          child: SocialLoginButtons(onApplePressed: null),
        ),
      );

      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.byIcon(LineIcons.apple), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(LineIcons.apple)).color,
        Colors.black,
      );
      expect(
        tester.widget<Text>(find.text('Continue with Apple')).style?.color,
        Colors.black,
      );
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );

  testWidgets(
    'social login buttons can render Apple when the availability gate is enabled',
    (tester) async {
      await tester.pumpWidget(
        const _Harness(
          locale: Locale('en'),
          child: SocialLoginButtons(showApple: true, onApplePressed: null),
        ),
      );

      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.byIcon(LineIcons.apple), findsOneWidget);
    },
  );

  testWidgets(
    'social login buttons hide Apple on unsupported platforms',
    (tester) async {
      await tester.pumpWidget(
        const _Harness(
          locale: Locale('en'),
          child: SocialLoginButtons(onApplePressed: null),
        ),
      );

      expect(find.text('Continue with Apple'), findsNothing);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
      TargetPlatform.macOS,
    }),
  );

  testWidgets(
    'social login buttons render provider icons without a badge box',
    (tester) async {
      await tester.pumpWidget(
        const _Harness(
          locale: Locale('en'),
          child: SocialLoginButtons(
            onSteamPressed: _noop,
            showDiscord: true,
            onDiscordPressed: _noop,
            showApple: true,
            onApplePressed: _noop,
          ),
        ),
      );

      expect(
        find.ancestor(
          of: find.byIcon(LineIcons.steam),
          matching: find.byType(DecoratedBox),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byIcon(LineIcons.discord),
          matching: find.byType(DecoratedBox),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byIcon(LineIcons.apple),
          matching: find.byType(DecoratedBox),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('social login buttons avoid overflow at larger text scales', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        locale: Locale('de'),
        textScaler: TextScaler.linear(1.6),
        child: SocialLoginButtons(
          onSteamPressed: _noop,
          showDiscord: true,
          onDiscordPressed: _noop,
          showApple: true,
          onApplePressed: _noop,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
