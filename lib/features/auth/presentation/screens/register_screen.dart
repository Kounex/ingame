import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../data/auth_repository.dart';
import '../../../../shared/widgets/tappable.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({
    super.key,
    this.redirectTo,
  });

  final String? redirectTo;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Timer? _emailDebounce;
  Timer? _displayNameDebounce;

  bool _emailChecking = false;
  bool _displayNameChecking = false;
  String? _emailAvailabilityError;
  String? _displayNameAvailabilityError;

  static const _debounceDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _displayNameController.addListener(_onDisplayNameChanged);
  }

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _displayNameDebounce?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _displayNameController.removeListener(_onDisplayNameChanged);
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    _emailDebounce?.cancel();
    final email = _emailController.text.trim();

    if (email.isEmpty || FormValidators.email(email) != null) {
      setState(() {
        _emailAvailabilityError = null;
        _emailChecking = false;
      });
      return;
    }

    setState(() => _emailChecking = true);

    _emailDebounce = Timer(_debounceDuration, () async {
      try {
        final repo = ref.read(authRepositoryProvider);
        final available = await repo.checkEmailAvailable(email);
        if (mounted && _emailController.text.trim() == email) {
          setState(() {
            _emailChecking = false;
            _emailAvailabilityError =
                available ? null : 'This email is already taken';
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _emailChecking = false);
        }
      }
    });
  }

  void _onDisplayNameChanged() {
    _displayNameDebounce?.cancel();
    final name = _displayNameController.text.trim();

    if (name.isEmpty || FormValidators.displayName(name) != null) {
      setState(() {
        _displayNameAvailabilityError = null;
        _displayNameChecking = false;
      });
      return;
    }

    setState(() => _displayNameChecking = true);

    _displayNameDebounce = Timer(_debounceDuration, () async {
      try {
        final repo = ref.read(authRepositoryProvider);
        final available = await repo.checkDisplayNameAvailable(name);
        if (mounted && _displayNameController.text.trim() == name) {
          setState(() {
            _displayNameChecking = false;
            _displayNameAvailabilityError =
                available ? null : 'This display name is already taken';
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _displayNameChecking = false);
        }
      }
    });
  }

  void _onRegister() {
    if (_emailAvailabilityError != null ||
        _displayNameAvailabilityError != null) {
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authNotifierProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim(),
          );
    }
  }

  Widget _buildAvailabilityIndicator({
    required bool checking,
    required String? error,
  }) {
    if (checking) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textTertiary,
        ),
      );
    }
    if (error != null) {
      return const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenData((state) {
        state.whenOrNull(
          authenticated: (_) => context.go(widget.redirectTo ?? RoutePaths.home),
        );
      });
    });

    String? errorMessage;
    bool loading = false;
    authState.whenData((state) {
      state.when(
        initial: () {},
        loading: () => loading = true,
        authenticated: (_) {},
        unauthenticated: () {},
        error: (msg) => errorMessage = msg,
      );
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
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.xxl),
                      GlassInput(
                        controller: _displayNameController,
                        label: 'Display Name',
                        hint: 'Choose a display name',
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.person_outline,
                        suffixIcon: _buildAvailabilityIndicator(
                          checking: _displayNameChecking,
                          error: _displayNameAvailabilityError,
                        ),
                        validator: (value) {
                          final base = FormValidators.displayName(value);
                          if (base != null) return base;
                          if (_displayNameAvailabilityError != null) {
                            return _displayNameAvailabilityError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GlassInput(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.email_outlined,
                        suffixIcon: _buildAvailabilityIndicator(
                          checking: _emailChecking,
                          error: _emailAvailabilityError,
                        ),
                        validator: (value) {
                          final base = FormValidators.email(value);
                          if (base != null) return base;
                          if (_emailAvailabilityError != null) {
                            return _emailAvailabilityError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GlassInput(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Create a password',
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.lock_outline,
                        validator: FormValidators.password,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GlassInput(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Confirm your password',
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onRegister(),
                        prefixIcon: Icons.lock_outline,
                        validator: (value) => FormValidators.confirmPassword(
                          value,
                          _passwordController.text,
                        ),
                      ),
                      if (errorMessage != null) ...[
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
                            errorMessage!,
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
                        onPressed: loading ? null : _onRegister,
                        variant: GlassButtonVariant.primary,
                        isLoading: loading,
                        child: const Text('Create Account'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildLoginLink(),
                    ],
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
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ).createShader(bounds),
          child: const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Join the community',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
        Tappable(
          onTap: () => context.go(
            Uri(
              path: RoutePaths.login,
              queryParameters: widget.redirectTo == null
                  ? null
                  : {'from': widget.redirectTo!},
            ).toString(),
          ),
          child: const Text(
            'Log in',
            style: TextStyle(
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
