import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/networking/app_failure.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../data/oauth_launcher.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';
import 'steam_auth_screen.dart';

class DiscordAuthScreen extends ConsumerStatefulWidget {
  const DiscordAuthScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<DiscordAuthScreen> createState() => _DiscordAuthScreenState();
}

class _DiscordAuthScreenState extends ConsumerState<DiscordAuthScreen> {
  AppFailure? _error;

  @override
  void initState() {
    super.initState();
    _startDiscordAuth();
  }

  Future<void> _startDiscordAuth() async {
    try {
      final authResult = await OAuthLauncher.launchDiscordAuth();
      if (!mounted) return;
      await ref
          .read(authNotifierProvider.notifier)
          .completeDiscordLogin(authResult);
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
    _startDiscordAuth();
  }

  void _goBackToLogin() {
    context.go(
      Uri(
        path: RoutePaths.login,
        queryParameters: widget.redirectTo == null
            ? null
            : {'from': widget.redirectTo!},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenData((state) {
        state.whenOrNull(
          authenticated: (_) =>
              context.go(widget.redirectTo ?? RoutePaths.home),
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
      message: context.l10n.discordAuthConnecting,
      onCancel: _goBackToLogin,
    );
  }

  Widget _buildError(AppFailure failure) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            failure.userMessage(context.l10n),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassButton(
            onPressed: _retry,
            variant: GlassButtonVariant.secondary,
            child: Text(context.l10n.steamAuthTryAgain),
          ),
          const SizedBox(height: AppSpacing.md),
          SteamAuthBackToLoginRow(onTap: _goBackToLogin),
        ],
      ),
    );
  }
}
