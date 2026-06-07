import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_aware_form_state_mixin.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/networking/app_failure.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/widgets/ingame_logo.dart';
import '../../../../shared/widgets/tappable.dart';
import '../widgets/social_login_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with LocaleAwareFormStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hasAttemptedSubmit = false;

  void _clearAuthErrorIfNeeded() {
    ref.read(authNotifierProvider.notifier).clearError();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    _hasAttemptedSubmit = true;
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authNotifierProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final l10n = context.l10n;

    revalidateFormOnLocaleChange(
      formKey: _formKey,
      shouldRevalidate: _hasAttemptedSubmit,
    );

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenData((state) {
        state.whenOrNull(
          authenticated: (_) =>
              context.go(widget.redirectTo ?? RoutePaths.home),
        );
      });
    });

    AppFailure? errorFailure;
    bool loading = false;
    authState.whenData((state) {
      state.when(
        initial: () {},
        loading: () => loading = true,
        authenticated: (_) {},
        unauthenticated: () {},
        error: (failure) => errorFailure = failure,
      );
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackgroundSurface(
        child: SafeArea(
          child: Center(
            child: DesktopContentRegion(
              width: DesktopContentWidth.compact,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LanguageSwitcher(
                          mode: LanguageSwitcherMode.compact,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildHeader(),
                        const SizedBox(height: AppSpacing.xxl),
                        GlassInput(
                          controller: _emailController,
                          label: l10n.loginEmailLabel,
                          hint: l10n.loginEmailHint,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.email_outlined,
                          onChanged: (_) => _clearAuthErrorIfNeeded(),
                          validator: FormValidators.email,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GlassInput(
                          controller: _passwordController,
                          label: l10n.loginPasswordLabel,
                          hint: l10n.loginPasswordHint,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onLogin(),
                          onChanged: (_) => _clearAuthErrorIfNeeded(),
                          prefixIcon: Icons.lock_outline,
                          validator: FormValidators.password,
                        ),
                        if (errorFailure != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              errorFailure!.userMessage(l10n),
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        GlassButton(
                          onPressed: loading ? null : _onLogin,
                          variant: GlassButtonVariant.primary,
                          isLoading: loading,
                          child: Text(l10n.loginSubmit),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SocialLoginButtons(
                          onSteamPressed: () => context.go(
                            Uri(
                              path: RoutePaths.steamAuth,
                              queryParameters: widget.redirectTo == null
                                  ? null
                                  : {'from': widget.redirectTo!},
                            ).toString(),
                          ),
                          onDiscordPressed: () => context.go(
                            Uri(
                              path: RoutePaths.discordAuth,
                              queryParameters: widget.redirectTo == null
                                  ? null
                                  : {'from': widget.redirectTo!},
                            ).toString(),
                          ),
                          onApplePressed: () => ref
                              .read(authNotifierProvider.notifier)
                              .appleLogin(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildRegisterLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const InGameLogo(size: InGameLogoSize.large, showTagline: true);
  }

  Widget _buildRegisterLink() {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.loginNoAccount,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
        const SizedBox(width: 4),
        Tappable(
          onTap: () {
            _clearAuthErrorIfNeeded();
            context.go(
              Uri(
                path: RoutePaths.register,
                queryParameters: widget.redirectTo == null
                    ? null
                    : {'from': widget.redirectTo!},
              ).toString(),
            );
          },
          child: Text(
            l10n.loginRegister,
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
