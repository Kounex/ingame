import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/provider_visuals.dart';
import '../../data/oauth_launcher.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({
    super.key,
    this.onSteamPressed,
    this.onDiscordPressed,
    this.onApplePressed,
    this.showDiscord,
    this.showApple,
  });

  final VoidCallback? onSteamPressed;
  final VoidCallback? onDiscordPressed;
  final VoidCallback? onApplePressed;
  @visibleForTesting
  final bool? showDiscord;
  @visibleForTesting
  final bool? showApple;

  @override
  Widget build(BuildContext context) {
    final showDiscordButton =
        showDiscord ?? OAuthLauncher.discordSignInAvailable;
    final showAppleButton = showApple ?? OAuthLauncher.appleSignInAvailable;

    return Column(
      children: [
        const _SocialDivider(),
        const SizedBox(height: AppSpacing.lg),
        _ProviderAuthButton(
          provider: 'steam',
          label: context.l10n.socialContinueWithSteam,
          onPressed: onSteamPressed,
        ),
        if (showDiscordButton) ...[
          const SizedBox(height: AppSpacing.sm),
          _ProviderAuthButton(
            provider: 'discord',
            label: context.l10n.socialContinueWithDiscord,
            onPressed: onDiscordPressed,
          ),
        ],
        if (showAppleButton) ...[
          const SizedBox(height: AppSpacing.sm),
          _ProviderAuthButton(
            provider: 'apple',
            label: context.l10n.socialContinueWithApple,
            onPressed: onApplePressed,
          ),
        ],
      ],
    );
  }
}

class _ProviderAuthButton extends StatelessWidget {
  const _ProviderAuthButton({
    required this.provider,
    required this.label,
    this.onPressed,
  });

  final String provider;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final spec = ProviderVisuals.forProvider(provider);
    return _HoverableSocialButton(
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [spec.authBackgroundStart, spec.authBackgroundEnd],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: spec.authBorderColor, width: 1.5),
          boxShadow: spec.authShadowColor == null
              ? null
              : [BoxShadow(color: spec.authShadowColor!, blurRadius: 10)],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(
                    child: Icon(
                      spec.icon,
                      size: provider == 'apple' ? 20 : 18,
                      color: spec.authIconColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: spec.authForegroundColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverableSocialButton extends StatelessWidget {
  const _HoverableSocialButton({required this.child, this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final wrappedChild = Semantics(
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          mouseCursor: onPressed != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: child,
        ),
      ),
    );

    if (onPressed == null) {
      return wrappedChild;
    }

    return Cue.onHover(
      cursor: SystemMouseCursors.click,
      motion: .easeOut(180.ms),
      acts: [const .scale(to: 1.015)],
      child: wrappedChild,
    );
  }
}

class _SocialDivider extends StatelessWidget {
  const _SocialDivider();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            l10n.socialDividerOr,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
