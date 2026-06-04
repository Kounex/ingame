import 'dart:async';

import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_aware_form_state_mixin.dart';
import '../../../../core/networking/app_failure.dart';
import '../../../../core/networking/api_error.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/routing/route_normalization.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../../../shared/widgets/editable_avatar_field.dart';
import '../../../../shared/widgets/weekly_availability_editor.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../onboarding_profile_validation.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/widgets/timezone_selector.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with LocaleAwareFormStateMixin {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  static const _debounceDuration = Duration(milliseconds: 600);

  int _currentPage = 0;

  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  Timer? _emailDebounce;
  String? _initialEmail;
  String? _avatarUrl;
  String? _initialAvatarUrl;
  late String _timezone;
  bool _avatarChanged = false;

  Map<String, dynamic> _selectedGamingHours = {};
  bool _isSaving = false;
  bool _hasAttemptedProfileValidation = false;
  bool _emailChecking = false;
  AppFailure? _emailAvailabilityError;

  @override
  void initState() {
    super.initState();
    final user = ref
        .read(authNotifierProvider)
        .maybeWhen(
          data: (s) => s.maybeWhen(authenticated: (u) => u, orElse: () => null),
          orElse: () => null,
        );
    _initialEmail = user?.email?.trim();
    _displayNameController = TextEditingController(
      text: user?.displayName ?? '',
    );
    _emailController = TextEditingController(text: user?.email ?? '');
    _bioController = TextEditingController();
    _avatarUrl = user?.avatarUrl;
    _initialAvatarUrl = user?.avatarUrl;
    _timezone = user?.timezone ?? 'America/New_York';
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _pageController.dispose();
    _emailController.removeListener(_onEmailChanged);
    _displayNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    _emailDebounce?.cancel();
    final email = _emailController.text.trim();

    if (email.isEmpty || FormValidators.email(email) != null) {
      setState(() {
        _emailChecking = false;
        _emailAvailabilityError = null;
      });
      return;
    }

    if (email == _initialEmail) {
      setState(() {
        _emailChecking = false;
        _emailAvailabilityError = null;
      });
      return;
    }

    setState(() {
      _emailChecking = true;
      _emailAvailabilityError = null;
    });

    _emailDebounce = Timer(_debounceDuration, () async {
      try {
        final repo = ref.read(authRepositoryProvider);
        final available = await repo.checkEmailAvailable(email);
        if (!mounted || _emailController.text.trim() != email) return;
        setState(() {
          _emailChecking = false;
          _emailAvailabilityError = available
              ? null
              : const LocalizedFailure(AppFailureMessageKey.registerEmailTaken);
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _emailChecking = false);
      }
    });
  }

  Widget _buildAvailabilityIndicator({
    required bool checking,
    required AppFailure? error,
  }) {
    if (checking) {
      return const SizedBox(
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: 12),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      );
    }
    if (error != null) {
      return const SizedBox(
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: 12),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Icon(
              Icons.cancel_outlined,
              color: AppColors.error,
              size: 16,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _goToPage(int page) {
    if (page == 1 || page == 2) {
      if (_currentPage == 1 && page == 2) {
        _hasAttemptedProfileValidation = true;
        if (!_validateProfileStep()) return;
      }
    }
    _pageController
        .animateToPage(
          page,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (!mounted) return;
          if (page == 1 && _hasAttemptedProfileValidation) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _formKey.currentState?.validate();
            });
          }
        });
  }

  bool _validateProfileStep() {
    final formState = _formKey.currentState;
    if (formState != null) {
      return formState.validate();
    }
    return isOnboardingProfileSubmissionValid(
      displayName: _displayNameController.text,
      email: _emailController.text,
      hasEmailAvailabilityError: _emailAvailabilityError != null,
    );
  }

  Future<void> _finish() async {
    _hasAttemptedProfileValidation = true;
    if (!_validateProfileStep()) {
      _goToPage(1);
      return;
    }

    if (_emailChecking) {
      AppToast.error(context, context.l10n.errorCheckInput);
      return;
    }

    setState(() => _isSaving = true);

    final updates = <String, dynamic>{
      'email': _emailController.text.trim(),
      'display_name': _displayNameController.text.trim(),
      'bio': _bioController.text.trim().isEmpty
          ? context.l10n.onboardingDefaultBio
          : _bioController.text.trim(),
      'timezone': _timezone,
      if (_avatarChanged) 'avatar_url': _avatarUrl,
      if (_selectedGamingHours.isNotEmpty)
        'preferred_gaming_hours': _selectedGamingHours,
    };

    await ref.read(profileNotifierProvider.notifier).updateProfile(updates);

    if (!mounted) return;

    final profileState = ref.read(profileNotifierProvider);
    if (profileState.hasError) {
      setState(() => _isSaving = false);
      AppToast.error(
        context,
        ApiError.userMessage(profileState.error!, context.l10n),
      );
      return;
    }

    ref.invalidate(authNotifierProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref
        .watch(authNotifierProvider)
        .maybeWhen(
          data: (state) => state.maybeWhen(
            authenticated: (user) => user,
            orElse: () => null,
          ),
          orElse: () => null,
        );
    final showConnectSteamCta = authUser?.steamId == null;

    if (authUser != null) {
      if (_displayNameController.text.isEmpty &&
          authUser.displayName.isNotEmpty) {
        _displayNameController.text = authUser.displayName;
      }
      if ((_initialEmail == null || _initialEmail!.isEmpty) &&
          authUser.email != null &&
          authUser.email!.trim().isNotEmpty) {
        _initialEmail = authUser.email!.trim();
        if (_emailController.text.isEmpty) {
          _emailController.text = authUser.email!;
        }
      }
      if (!_avatarChanged &&
          (_initialAvatarUrl == null || _initialAvatarUrl!.isEmpty) &&
          authUser.avatarUrl != null &&
          authUser.avatarUrl!.isNotEmpty) {
        _initialAvatarUrl = authUser.avatarUrl;
        _avatarUrl = authUser.avatarUrl;
      }
    }

    revalidateFormOnLocaleChange(
      formKey: _formKey,
      shouldRevalidate:
          _currentPage == 1 &&
          (_hasAttemptedProfileValidation || _emailAvailabilityError != null),
    );

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenData((state) {
        state.whenOrNull(
          authenticated: (user) {
            final hasEmail =
                user.email != null && user.email!.trim().isNotEmpty;
            final hasBio = user.bio != null && user.bio!.isNotEmpty;
            if (!hasEmail || !hasBio || !mounted) {
              return;
            }

            final from = sanitizeRedirectTarget(
              GoRouterState.of(context).uri.queryParameters['from'],
            );
            context.go(from ?? RoutePaths.home);
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
          child: DesktopContentRegion(
            width: DesktopContentWidth.form,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                _StepIndicator(currentPage: _currentPage, pageCount: 3),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [
                      _WelcomePage(onGetStarted: () => _goToPage(1)),
                      _ProfileSetupPage(
                        formKey: _formKey,
                        displayNameController: _displayNameController,
                        emailController: _emailController,
                        bioController: _bioController,
                        avatarUrl: _avatarUrl,
                        avatarDisplayName:
                            _displayNameController.text.trim().isEmpty
                            ? (authUser?.displayName ??
                                  context.l10n.profileUnknown)
                            : _displayNameController.text.trim(),
                        onAvatarChanged: (value) {
                          setState(() {
                            _avatarUrl = value;
                            _avatarChanged = value != _initialAvatarUrl;
                          });
                        },
                        emailChecking: _emailChecking,
                        emailAvailabilityError: _emailAvailabilityError,
                        buildAvailabilityIndicator: _buildAvailabilityIndicator,
                        timezone: _timezone,
                        onTimezoneChanged: (value) {
                          setState(() => _timezone = value);
                        },
                        onBack: () => _goToPage(0),
                        onNext: () => _goToPage(2),
                      ),
                      _GamingPreferencesPage(
                        initialHours: _selectedGamingHours,
                        showConnectSteamCta: showConnectSteamCta,
                        onHoursChanged: (hours) => _selectedGamingHours = hours,
                        onBack: () => _goToPage(1),
                        onFinish: _finish,
                        isSaving: _isSaving,
                      ),
                    ],
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

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentPage, required this.pageCount});

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Cue.onChange(
      value: currentPage,
      motion: .easeOut(250.ms),
      fromCurrentValue: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (index) {
            final isActive = index == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Actor(
                acts: [
                  .sizedBox(
                    width: .tween(isActive ? 8.0 : 24.0, isActive ? 24.0 : 8.0),
                    height: const .fixed(8),
                  ),
                  .decorate(
                    color: .tween(
                      isActive ? AppColors.textTertiary : AppColors.primary,
                      isActive ? AppColors.primary : AppColors.textTertiary,
                    ),
                    borderRadius: .fixed(BorderRadius.circular(4)),
                  ),
                ],
                child: const SizedBox(),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
                radius: 0.8,
              ),
            ),
            child: const Icon(
              Icons.sports_esports,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.l10n.onboardingWelcomeTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.onboardingWelcomeSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              onPressed: onGetStarted,
              child: Text(context.l10n.onboardingGetStarted),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ProfileSetupPage extends StatelessWidget {
  const _ProfileSetupPage({
    required this.formKey,
    required this.displayNameController,
    required this.emailController,
    required this.bioController,
    required this.avatarUrl,
    required this.avatarDisplayName,
    required this.onAvatarChanged,
    required this.emailChecking,
    required this.emailAvailabilityError,
    required this.buildAvailabilityIndicator,
    required this.timezone,
    required this.onTimezoneChanged,
    required this.onBack,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController bioController;
  final String? avatarUrl;
  final String avatarDisplayName;
  final ValueChanged<String?> onAvatarChanged;
  final bool emailChecking;
  final AppFailure? emailAvailabilityError;
  final Widget Function({required bool checking, required AppFailure? error})
  buildAvailabilityIndicator;
  final String timezone;
  final ValueChanged<String> onTimezoneChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(
              context.l10n.onboardingProfileTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.onboardingProfileSubtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GlassCard(
              animate: true,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  EditableAvatarField(
                    initialAvatarUrl: avatarUrl,
                    displayName: avatarDisplayName,
                    onChanged: onAvatarChanged,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassInput(
                    controller: displayNameController,
                    label: context.l10n.registerDisplayNameLabel,
                    hint: context.l10n.onboardingDisplayNameHint,
                    prefixIcon: Icons.person_outline,
                    validator: FormValidators.displayName,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassInput(
                    controller: emailController,
                    label: context.l10n.loginEmailLabel,
                    hint: context.l10n.loginEmailHint,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    errorText: emailAvailabilityError?.userMessage(
                      context.l10n,
                    ),
                    suffixIcon: buildAvailabilityIndicator(
                      checking: emailChecking,
                      error: emailAvailabilityError,
                    ),
                    validator: (value) {
                      final base = FormValidators.email(value);
                      if (base != null) return base;
                      if (emailAvailabilityError != null) {
                        return emailAvailabilityError!.userMessage(
                          context.l10n,
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassInput(
                    controller: bioController,
                    label: context.l10n.onboardingBioLabel,
                    hint: context.l10n.onboardingBioHint,
                    prefixIcon: Icons.info_outline,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TimezoneSelector(
                    selectedTimezone: timezone,
                    onChanged: onTimezoneChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    variant: GlassButtonVariant.ghost,
                    onPressed: onBack,
                    child: Text(context.l10n.commonBack),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GlassButton(
                    onPressed: onNext,
                    child: Text(context.l10n.commonNext),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _GamingPreferencesPage extends StatelessWidget {
  const _GamingPreferencesPage({
    required this.initialHours,
    required this.showConnectSteamCta,
    required this.onHoursChanged,
    required this.onBack,
    required this.onFinish,
    required this.isSaving,
  });

  final Map<String, dynamic> initialHours;
  final bool showConnectSteamCta;
  final ValueChanged<Map<String, dynamic>> onHoursChanged;
  final VoidCallback onBack;
  final VoidCallback onFinish;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.l10n.onboardingGamingTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.onboardingGamingSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GlassCard(
            animate: true,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: WeeklyAvailabilityEditor(
              initialHours: initialHours,
              onChanged: onHoursChanged,
              showTitle: false,
            ),
          ),
          if (showConnectSteamCta) ...[
            const SizedBox(height: AppSpacing.xl),
            GlassCard(
              animate: true,
              animationDelay: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.games_outlined,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.onboardingConnectSteamTitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.onboardingConnectSteamSubtitle,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  variant: GlassButtonVariant.ghost,
                  onPressed: isSaving ? null : onBack,
                  child: Text(context.l10n.commonBack),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GlassButton(
                  onPressed: isSaving ? null : onFinish,
                  isLoading: isSaving,
                  child: Text(context.l10n.commonFinish),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
