import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/networking/app_failure.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/tappable.dart';
import '../../data/oauth_launcher.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

class SteamAuthScreen extends ConsumerStatefulWidget {
  const SteamAuthScreen({
    super.key,
    this.redirectTo,
  });

  final String? redirectTo;

  @override
  ConsumerState<SteamAuthScreen> createState() => _SteamAuthScreenState();
}

class _SteamAuthScreenState extends ConsumerState<SteamAuthScreen> {
  AppFailure? _error;

  @override
  void initState() {
    super.initState();
    _startSteamAuth();
  }

  Future<void> _startSteamAuth() async {
    try {
      final params = await OAuthLauncher.launchSteamAuth();
      if (!mounted) return;
      await ref.read(authNotifierProvider.notifier).steamLogin(params);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = OAuthLauncher.toFailure(e);
      });
    }
  }

  void _retry() {
    setState(() {
      _error = null;
    });
    _startSteamAuth();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenData((state) {
        state.whenOrNull(
          authenticated: (_) => context.go(widget.redirectTo ?? RoutePaths.home),
          error: (failure) {
            if (mounted) {
              setState(() {
                _error = failure;
              });
            }
          },
        );
      });
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackgroundSurface(
        child: SafeArea(
          child: Center(
            child: DesktopContentRegion(
              width: DesktopContentWidth.compact,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _error != null ? _buildError(_error!) : _buildLoading(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return SteamAuthLoadingView(
      onCancel: () => context.go(
        Uri(
          path: RoutePaths.login,
          queryParameters: widget.redirectTo == null
              ? null
              : {'from': widget.redirectTo!},
        ).toString(),
      ),
    );
  }

  Widget _buildError(AppFailure failure) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            failure.userMessage(context.l10n),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassButton(
            onPressed: _retry,
            variant: GlassButtonVariant.secondary,
            child: Text(context.l10n.steamAuthTryAgain),
          ),
          const SizedBox(height: AppSpacing.md),
          SteamAuthBackToLoginRow(
            onTap: () => context.go(
              Uri(
                path: RoutePaths.login,
                queryParameters: widget.redirectTo == null
                    ? null
                    : {'from': widget.redirectTo!},
              ).toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class SteamAuthBackToLoginRow extends StatelessWidget {
  const SteamAuthBackToLoginRow({
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.l10n.steamAuthBackToPrefix,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
        const SizedBox(width: 4),
        Tappable(
          onTap: onTap,
          child: Text(
            context.l10n.registerLogin,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class SteamAuthLoadingView extends StatelessWidget {
  const SteamAuthLoadingView({
    required this.onCancel,
    super.key,
  });

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.steamAuthConnecting,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassButton(
            onPressed: onCancel,
            variant: GlassButtonVariant.secondary,
            child: Text(context.l10n.commonCancel),
          ),
          const SizedBox(height: AppSpacing.md),
          SteamAuthBackToLoginRow(onTap: onCancel),
        ],
      ),
    );
  }
}
