import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/loading_indicator.dart';
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
  String? _error;

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
        _error = OAuthLauncher.friendlyError(e);
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
          error: (msg) {
            if (mounted) {
              setState(() {
                _error = msg;
              });
            }
          },
        );
      });
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _error != null ? _buildError() : _buildLoading(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LoadingIndicator(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.steamAuthConnecting,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
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
            _error!,
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
          const SizedBox(height: AppSpacing.sm),
          GlassButton(
            onPressed: () => context.go(
              Uri(
                path: RoutePaths.login,
                queryParameters: widget.redirectTo == null
                    ? null
                    : {'from': widget.redirectTo!},
              ).toString(),
            ),
            variant: GlassButtonVariant.ghost,
            child: Text(context.l10n.steamAuthBackToLogin),
          ),
        ],
      ),
    );
  }
}
