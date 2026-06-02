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
import '../../../../shared/widgets/tappable.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/onboarding_provider.dart';

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
  late TextEditingController _avatarUrlController;
  Timer? _emailDebounce;
  String? _initialEmail;

  final Set<String> _selectedTimeSlots = {};
  bool _isSaving = false;
  bool _hasAttemptedProfileValidation = false;
  bool _emailChecking = false;
  AppFailure? _emailAvailabilityError;

  List<(String, String, String, IconData)> _timeSlots(BuildContext context) => [
    (
      'morning',
      context.l10n.timeSlotMorningLabel,
      context.l10n.timeSlotMorningSubtitle,
      Icons.wb_sunny_outlined,
    ),
    (
      'afternoon',
      context.l10n.timeSlotAfternoonLabel,
      context.l10n.timeSlotAfternoonSubtitle,
      Icons.wb_cloudy_outlined,
    ),
    (
      'evening',
      context.l10n.timeSlotEveningLabel,
      context.l10n.timeSlotEveningSubtitle,
      Icons.nights_stay_outlined,
    ),
    (
      'night',
      context.l10n.timeSlotNightLabel,
      context.l10n.timeSlotNightSubtitle,
      Icons.dark_mode_outlined,
    ),
  ];

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
    _avatarUrlController = TextEditingController();
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
    _avatarUrlController.dispose();
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

    setState(() => _emailChecking = true);

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
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textTertiary,
        ),
      );
    }
    if (error != null) {
      return const Icon(
        Icons.cancel_outlined,
        color: AppColors.error,
        size: 20,
      );
    }
    return const SizedBox.shrink();
  }

  void _goToPage(int page) {
    if (page == 1 || page == 2) {
      if (_currentPage == 1 && page == 2) {
        _hasAttemptedProfileValidation = true;
        if (!_formKey.currentState!.validate()) return;
      }
    }
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Map<String, dynamic> _buildGamingHours() {
    if (_selectedTimeSlots.isEmpty) return {};
    final Map<String, dynamic> hours = {};
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final ranges = <String, Map<String, String>>{
      'morning': {'start': '06:00', 'end': '12:00'},
      'afternoon': {'start': '12:00', 'end': '18:00'},
      'evening': {'start': '18:00', 'end': '00:00'},
      'night': {'start': '00:00', 'end': '06:00'},
    };

    final slots = _selectedTimeSlots.map((s) => ranges[s]!).toList();

    for (final day in days) {
      hours[day] = slots;
    }
    return hours;
  }

  Future<void> _finish() async {
    _hasAttemptedProfileValidation = true;
    if (!_formKey.currentState!.validate()) {
      _goToPage(1);
      return;
    }

    if (_emailChecking) {
      AppToast.error(context, context.l10n.errorCheckInput);
      return;
    }

    setState(() => _isSaving = true);

    final gamingHours = _buildGamingHours();
    final updates = <String, dynamic>{
      'email': _emailController.text.trim(),
      'display_name': _displayNameController.text.trim(),
      'bio': _bioController.text.trim().isEmpty
          ? context.l10n.onboardingDefaultBio
          : _bioController.text.trim(),
      if (_avatarUrlController.text.trim().isNotEmpty)
        'avatar_url': _avatarUrlController.text.trim(),
      if (gamingHours.isNotEmpty) 'preferred_gaming_hours': gamingHours,
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
    }

    revalidateFormOnLocaleChange(
      formKey: _formKey,
      shouldRevalidate:
          _currentPage == 1 &&
          (_hasAttemptedProfileValidation || _emailAvailabilityError != null),
    );

    ref.listen<bool>(needsOnboardingProvider, (_, needsOnboarding) {
      if (!needsOnboarding && mounted) {
        final from = sanitizeRedirectTarget(
          GoRouterState.of(context).uri.queryParameters['from'],
        );
        context.go(from ?? RoutePaths.home);
      }
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
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              _StepIndicator(currentPage: _currentPage, pageCount: 3),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _WelcomePage(onGetStarted: () => _goToPage(1)),
                    _ProfileSetupPage(
                      formKey: _formKey,
                      displayNameController: _displayNameController,
                      emailController: _emailController,
                      bioController: _bioController,
                      avatarUrlController: _avatarUrlController,
                      emailChecking: _emailChecking,
                      emailAvailabilityError: _emailAvailabilityError,
                      buildAvailabilityIndicator: _buildAvailabilityIndicator,
                      onBack: () => _goToPage(0),
                      onNext: () => _goToPage(2),
                    ),
                    _GamingPreferencesPage(
                      selectedTimeSlots: _selectedTimeSlots,
                      timeSlots: _timeSlots(context),
                      onToggleSlot: (slot) {
                        setState(() {
                          if (_selectedTimeSlots.contains(slot)) {
                            _selectedTimeSlots.remove(slot);
                          } else {
                            _selectedTimeSlots.add(slot);
                          }
                        });
                      },
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
    required this.avatarUrlController,
    required this.emailChecking,
    required this.emailAvailabilityError,
    required this.buildAvailabilityIndicator,
    required this.onBack,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController bioController;
  final TextEditingController avatarUrlController;
  final bool emailChecking;
  final AppFailure? emailAvailabilityError;
  final Widget Function({required bool checking, required AppFailure? error})
  buildAvailabilityIndicator;
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
                  const SizedBox(height: AppSpacing.md),
                  GlassInput(
                    controller: avatarUrlController,
                    label: context.l10n.onboardingAvatarUrlLabel,
                    hint: context.l10n.onboardingAvatarUrlHint,
                    prefixIcon: Icons.image_outlined,
                    keyboardType: TextInputType.url,
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
    required this.selectedTimeSlots,
    required this.timeSlots,
    required this.onToggleSlot,
    required this.onBack,
    required this.onFinish,
    required this.isSaving,
  });

  final Set<String> selectedTimeSlots;
  final List<(String, String, String, IconData)> timeSlots;
  final ValueChanged<String> onToggleSlot;
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
            child: Column(
              children: [
                for (final (key, label, subtitle, icon) in timeSlots)
                  _TimeSlotTile(
                    label: label,
                    subtitle: subtitle,
                    icon: icon,
                    selected: selectedTimeSlots.contains(key),
                    onTap: () => onToggleSlot(key),
                  ),
              ],
            ),
          ),
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
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
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

class _TimeSlotTile extends StatelessWidget {
  const _TimeSlotTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Cue.onToggle(
      toggled: selected,
      motion: .easeOut(200.ms),
      reverseMotion: .easeOut(200.ms),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Tappable(
          onTap: onTap,
          child: Actor(
            acts: [
              .decorate(
                color: .tween(
                  Colors.transparent,
                  AppColors.primary.withValues(alpha: 0.12),
                ),
                borderRadius: .fixed(BorderRadius.circular(12)),
                border: .tween(
                  Border.all(color: AppColors.glassBorder),
                  Border.all(color: AppColors.primary),
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Actor(
                    acts: [
                      const .colorTint(
                        from: AppColors.textTertiary,
                        to: AppColors.primary,
                      ),
                    ],
                    child: Icon(icon, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Actor(
                          acts: [
                            const .textStyle(
                              from: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              to: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                          child: Text(label),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Actor(
                    acts: [
                      .decorate(
                        color: const .tween(
                          Colors.transparent,
                          AppColors.primary,
                        ),
                        borderRadius: .fixed(BorderRadius.circular(999)),
                        border: .tween(
                          Border.all(color: AppColors.textTertiary, width: 1.5),
                          Border.all(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ],
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: Center(
                        child: Actor(
                          acts: [.fadeIn(), .scale(from: 0.6)],
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
