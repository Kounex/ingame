import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/tappable.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;

  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _avatarUrlController;

  final Set<String> _selectedTimeSlots = {};
  bool _isSaving = false;

  static const _timeSlots = [
    ('morning', 'Morning', '6 AM – 12 PM', Icons.wb_sunny_outlined),
    ('afternoon', 'Afternoon', '12 PM – 6 PM', Icons.wb_cloudy_outlined),
    ('evening', 'Evening', '6 PM – 12 AM', Icons.nights_stay_outlined),
    ('night', 'Night', '12 AM – 6 AM', Icons.dark_mode_outlined),
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
    _displayNameController = TextEditingController(
      text: user?.displayName ?? '',
    );
    _bioController = TextEditingController();
    _avatarUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page == 1 || page == 2) {
      if (_currentPage == 1 && page == 2) {
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
    if (_selectedTimeSlots.isEmpty) {
      AppToast.error(
        context,
        'Select at least one time slot to complete onboarding.',
      );
      return;
    }

    setState(() => _isSaving = true);

    final gamingHours = _buildGamingHours();
    final updates = <String, dynamic>{
      'display_name': _displayNameController.text.trim(),
      'bio': _bioController.text.trim().isEmpty
          ? 'InGame player'
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
      AppToast.error(context, profileState.error.toString());
      return;
    }

    ref.invalidate(authNotifierProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(needsOnboardingProvider, (_, needsOnboarding) {
      if (!needsOnboarding && mounted) {
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        context.go((from != null && from.isNotEmpty) ? from : RoutePaths.home);
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
                      bioController: _bioController,
                      avatarUrlController: _avatarUrlController,
                      onBack: () => _goToPage(0),
                      onNext: () => _goToPage(2),
                    ),
                    _GamingPreferencesPage(
                      selectedTimeSlots: _selectedTimeSlots,
                      timeSlots: _timeSlots,
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
          const Text(
            'Welcome to InGame',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Coordinate gaming sessions with friends',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              onPressed: onGetStarted,
              child: const Text('Get Started'),
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
    required this.bioController,
    required this.avatarUrlController,
    required this.onBack,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameController;
  final TextEditingController bioController;
  final TextEditingController avatarUrlController;
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
            const Text(
              'Set Up Your Profile',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Let other players know who you are.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xl),
            GlassCard(
              animate: true,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  GlassInput(
                    controller: displayNameController,
                    label: 'Display Name',
                    hint: 'How others will see you',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Display name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassInput(
                    controller: bioController,
                    label: 'Bio',
                    hint: 'Tell others about yourself (optional)',
                    prefixIcon: Icons.info_outline,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassInput(
                    controller: avatarUrlController,
                    label: 'Avatar URL',
                    hint: 'Link to your avatar image (optional)',
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
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GlassButton(
                    onPressed: onNext,
                    child: const Text('Next'),
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
          const Text(
            'Gaming Preferences',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Select at least one time slot so groups can see when you play.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect Steam',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Link your account later in settings',
                        style: TextStyle(
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
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GlassButton(
                  onPressed: isSaving ? null : onFinish,
                  isLoading: isSaving,
                  child: const Text('Finish'),
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
                        color: const .tween(Colors.transparent, AppColors.primary),
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
