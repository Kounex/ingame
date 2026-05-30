import 'package:cue/cue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({
    super.key,
    this.onSteamPressed,
    this.onApplePressed,
  });

  final VoidCallback? onSteamPressed;
  final VoidCallback? onApplePressed;

  bool get _showAppleButton {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SocialDivider(),
        const SizedBox(height: AppSpacing.lg),
        _SteamButton(onPressed: onSteamPressed),
        if (_showAppleButton) ...[
          const SizedBox(height: AppSpacing.sm),
          _AppleButton(onPressed: onApplePressed),
        ],
      ],
    );
  }
}

class _SteamButton extends StatelessWidget {
  const _SteamButton({this.onPressed});
  final VoidCallback? onPressed;

  static const _steamNavy = Color(0xFF1B2838);
  static const _steamBlue = Color(0xFF66C0F4);
  static const _steamMid = Color(0xFF2A475E);

  @override
  Widget build(BuildContext context) {
    return _HoverableSocialButton(
      onPressed: onPressed,
      child: DecoratedBoxActor(
        gradient: const .tween(
          LinearGradient(colors: [_steamMid, _steamNavy]),
          LinearGradient(colors: [Color(0xFF3A7EBF), _steamMid]),
        ),
        borderRadius: .fixed(BorderRadius.circular(12)),
        border: .tween(
          Border.all(color: _steamBlue.withValues(alpha: 0.3), width: 1.5),
          Border.all(color: _steamBlue.withValues(alpha: 0.6), width: 1.5),
        ),
        boxShadow: .tween(
          [BoxShadow(color: _steamBlue.withValues(alpha: 0.1), blurRadius: 6)],
          [
            BoxShadow(
              color: _steamBlue.withValues(alpha: 0.25),
              blurRadius: 12,
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBoxActor(
                color: .tween(
                  _steamBlue.withValues(alpha: 0.2),
                  _steamBlue.withValues(alpha: 0.28),
                ),
                borderRadius: .fixed(BorderRadius.circular(6)),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.sports_esports,
                    size: 16,
                    color: Color(0xFF66C0F4),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Actor(
                acts: [
                  .textStyle(
                    from: TextStyle(
                      color: Color(0xFFE1E8ED),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    to: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
                child: Text('Continue with Steam'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleButton extends StatelessWidget {
  const _AppleButton({this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _HoverableSocialButton(
      onPressed: onPressed,
      child: DecoratedBoxActor(
        color: const .tween(Color(0xFFF5F5F7), Colors.white),
        borderRadius: .fixed(BorderRadius.circular(12)),
        border: .tween(
          Border.all(color: Colors.white.withValues(alpha: 0.2)),
          Border.all(color: Colors.white.withValues(alpha: 0.9)),
        ),
        boxShadow: .tween(<BoxShadow>[], [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.18),
            blurRadius: 10,
          ),
        ]),
        child: const SizedBox(
          width: double.infinity,
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apple, size: 22, color: Colors.black),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Continue with Apple',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
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
    final wrappedChild = GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: child,
    );

    if (onPressed == null) {
      return MouseRegion(cursor: SystemMouseCursors.basic, child: wrappedChild);
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
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.glassBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
        ),
        Expanded(child: Divider(color: AppColors.glassBorder)),
      ],
    );
  }
}
