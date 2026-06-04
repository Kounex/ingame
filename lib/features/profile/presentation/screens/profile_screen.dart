import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/locale_aware_form_state_mixin.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/networking/api_error.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/weekly_availability_editor.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../auth/data/oauth_launcher.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/profile_repository.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, AppColors.backgroundLight],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: context.l10n.profileTitle),
        body: profileAsync.when(
          loading: () => const Center(child: LoadingIndicator()),
          error: (error, _) => ErrorDisplay(
            message: ApiError.userMessage(error, context.l10n),
            onRetry: () => ref.read(profileNotifierProvider.notifier).load(),
          ),
          data: (user) {
            if (user == null) {
              return ErrorDisplay(
                message: context.l10n.profileLoadError,
                onRetry: () =>
                    ref.read(profileNotifierProvider.notifier).load(),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: UserAvatar(
                      imageUrl: user.avatarUrl,
                      displayName: user.displayName,
                      size: 96,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: Text(
                        user.bio!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _AccountInfoCard(user: user),
                  const SizedBox(height: AppSpacing.md),
                  const _PreferencesCard(),
                  const SizedBox(height: AppSpacing.md),
                  _GamingHoursCard(gamingHours: user.preferredGamingHours),
                  const SizedBox(height: AppSpacing.md),
                  _ConnectedAccountsCard(
                    email: user.email,
                    hasPasswordLogin: user.hasPasswordLogin,
                    steamId: user.steamId,
                    appleId: user.appleId,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  GlassButton(
                    onPressed: () => context.goNamed(RouteNames.editProfile),
                    child: Text(context.l10n.profileEdit),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassButton(
                    variant: GlassButtonVariant.ghost,
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).logout();
                    },
                    child: Text(
                      context.l10n.profileLogout,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: AppColors.textTertiary.withValues(alpha: 0.8),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.user});

  final User user;

  static String _formatDate(DateTime date) {
    return DateFormat.yMMMd(Intl.getCurrentLocale()).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        Icons.email_outlined,
        context.l10n.profileEmailLabel,
        user.email ?? context.l10n.profileNotSet,
      ),
      (
        Icons.public,
        context.l10n.profileTimezoneLabel,
        user.timezone.replaceAll('_', ' '),
      ),
      (
        Icons.calendar_today_outlined,
        context.l10n.profileMemberSinceLabel,
        user.createdAt != null
            ? _formatDate(user.createdAt!)
            : context.l10n.profileUnknown,
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: context.l10n.profileSectionAccount),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                color: AppColors.glassBorder.withValues(alpha: 0.4),
                height: 1,
              ),
            _InfoRow(icon: rows[i].$1, label: rows[i].$2, value: rows[i].$3),
          ],
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: context.l10n.profileSectionPreferences),
          const SizedBox(height: AppSpacing.md),
          const LanguageSwitcher(mode: LanguageSwitcherMode.settingsRow),
        ],
      ),
    );
  }
}

class _GamingHoursCard extends StatelessWidget {
  const _GamingHoursCard({this.gamingHours});

  final Map<String, dynamic>? gamingHours;

  static const _dayOrder = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  String _formatSlot(Map<String, dynamic> slot) {
    final start = slot['start'] as String? ?? '';
    final end = slot['end'] as String? ?? '';
    return '$start-$end';
  }

  String _readableTime(String t) {
    if (t == '00:00') return '12 AM';
    final parts = t.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour > 12) return '${hour - 12} PM';
    return '$hour AM';
  }

  List<_ScheduleGroup> _buildGroups(BuildContext context) {
    if (gamingHours == null || gamingHours!.isEmpty) return [];

    final daySlots = <String, List<String>>{};
    for (final day in _dayOrder) {
      final raw = gamingHours![day];
      if (raw == null) continue;
      final slots = (raw as List<dynamic>).cast<Map<String, dynamic>>();
      daySlots[day] = slots.map(_formatSlot).toList()..sort();
    }

    final signatureToGroup = <String, List<String>>{};
    for (final day in _dayOrder) {
      final slots = daySlots[day];
      if (slots == null || slots.isEmpty) continue;
      final sig = slots.join('|');
      signatureToGroup.putIfAbsent(sig, () => []).add(day);
    }

    return signatureToGroup.entries.map((e) {
      final slotKeys = e.key.split('|');
      final presetKeys = slotKeys
          .map(weeklyAvailabilityPresetFromSerializedRange)
          .whereType<String>()
          .toSet();
      final slotLabels =
          weeklyAvailabilityHasAllDay(presetKeys) &&
              presetKeys.length == weeklyAvailabilityPresetOrder.length
          ? <String>[context.l10n.timeSlotAllDayLabel]
          : slotKeys.map((key) {
              final name = _slotName(context, key);
              if (name != null) return name;
              final parts = key.split('-');
              return '${_readableTime(parts[0])} – ${_readableTime(parts[1])}';
            }).toList();
      return _ScheduleGroup(
        days: e.value,
        slots: slotLabels,
        slotKeys: slotKeys,
      );
    }).toList();
  }

  String _daysLabel(List<String> days) {
    final l10n = currentAppLocalizations();
    if (days.length == 7) return l10n.profileEveryDay;
    if (days.length == 5 &&
        days.every((d) => !['saturday', 'sunday'].contains(d))) {
      return l10n.profileWeekdays;
    }
    if (days.length == 2 &&
        days.every((d) => ['saturday', 'sunday'].contains(d))) {
      return l10n.profileWeekends;
    }
    return days.map(_dayLabel).join(', ');
  }

  String _dayLabel(String day) {
    final l10n = currentAppLocalizations();
    return switch (day) {
      'monday' => l10n.dayMonShort,
      'tuesday' => l10n.dayTueShort,
      'wednesday' => l10n.dayWedShort,
      'thursday' => l10n.dayThuShort,
      'friday' => l10n.dayFriShort,
      'saturday' => l10n.daySatShort,
      'sunday' => l10n.daySunShort,
      _ => day,
    };
  }

  String? _slotName(BuildContext context, String key) {
    final preset = weeklyAvailabilityPresetFromSerializedRange(key);
    if (preset == null) return null;
    return weeklyAvailabilityPresetLabel(context, preset);
  }

  IconData? _slotIcon(String slotKey, BuildContext context) {
    final preset = weeklyAvailabilityPresetFromSerializedRange(slotKey);
    if (preset == null) return null;
    return weeklyAvailabilityPresetIcon(preset);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups(context);
    final hasHours = groups.isNotEmpty;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: context.l10n.profileSectionGamingHours),
          const SizedBox(height: AppSpacing.md),
          if (!hasHours)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule_outlined,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  context.l10n.profileNoSchedule,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          else
            for (final group in groups) ...[
              if (group != groups.first)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Divider(color: AppColors.glassBorder, height: 1),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _daysLabel(group.days),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (var i = 0; i < group.slots.length; i++)
                          _SlotChip(
                            label: group.slots[i],
                            icon:
                                group.slots[i] ==
                                    context.l10n.timeSlotAllDayLabel
                                ? weeklyAvailabilityPresetIcon('all-day')
                                : _slotIcon(group.slotKeys[i], context),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _ScheduleGroup {
  const _ScheduleGroup({
    required this.days,
    required this.slots,
    required this.slotKeys,
  });

  final List<String> days;
  final List<String> slots;
  final List<String> slotKeys;
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedAccountsCard extends ConsumerWidget {
  const _ConnectedAccountsCard({
    this.email,
    required this.hasPasswordLogin,
    this.steamId,
    this.appleId,
  });

  final String? email;
  final bool hasPasswordLogin;
  final String? steamId;
  final String? appleId;

  int _authMethodCount() {
    var count = 0;
    if (hasPasswordLogin) count++;
    if (steamId != null) count++;
    if (appleId != null) count++;
    return count;
  }

  Future<bool?> _confirmDisconnect(
    BuildContext context, {
    required String provider,
    required bool includeSteamWarning,
  }) {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: Text(l10n.profileDisconnectTitle(provider)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profileDisconnectMessage(provider)),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.profileDisconnectSessionNotice),
            if (includeSteamWarning) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.profileDisconnectSteamFeatureNotice),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.profileDisconnectKeepAnotherMethod),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.profileDisconnectAction,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshProviders(WidgetRef ref) {
    ref.read(profileNotifierProvider.notifier).load();
    ref.invalidate(authNotifierProvider);
  }

  Future<void> _handleSteamTap(BuildContext context, WidgetRef ref) async {
    if (steamId != null) {
      if (_authMethodCount() <= 1) {
        AppToast.error(context, context.l10n.profileLastAuthMethodRequired);
        return;
      }
      final confirmed = await _confirmDisconnect(
        context,
        provider: context.l10n.profileConnectedAccountsSteam,
        includeSteamWarning: true,
      );
      if (confirmed != true || !context.mounted) return;
      try {
        await ref.read(profileRepositoryProvider).unlinkSteam();
        _refreshProviders(ref);
        if (context.mounted) {
          AppToast.success(
            context,
            context.l10n.profileDisconnectedSuccess(
              context.l10n.profileConnectedAccountsSteam,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.error(
            context,
            context.l10n.profileDisconnectFailed(
              context.l10n.profileConnectedAccountsSteam,
              ApiError.userMessage(e, context.l10n),
            ),
          );
        }
      }
    } else {
      try {
        final params = await OAuthLauncher.launchSteamAuth();
        if (!context.mounted) return;
        await ref.read(profileRepositoryProvider).linkSteam(params);
        _refreshProviders(ref);
        if (context.mounted) {
          AppToast.success(context, context.l10n.profileSteamLinkedSuccess);
        }
      } catch (e) {
        if (!context.mounted) return;
        final msg = OAuthLauncher.toFailure(e).userMessage(context.l10n);
        if (!OAuthLauncher.isCancellationError(e)) {
          AppToast.error(context, context.l10n.profileLinkSteamFailed(msg));
        }
      }
    }
  }

  Future<void> _handleEmailTap(BuildContext context, WidgetRef ref) async {
    if (hasPasswordLogin) return;

    final result = await showDialog<({String email, String password})>(
      context: context,
      useRootNavigator: true,
      builder: (context) => const _SetEmailPasswordDialog(),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(profileRepositoryProvider)
          .setEmailPassword(email: result.email, password: result.password);
      _refreshProviders(ref);
      if (context.mounted) {
        AppToast.success(
          context,
          context.l10n.profileEmailPasswordAddedSuccess,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          context.l10n.profileSetEmailFailed(
            ApiError.userMessage(e, context.l10n),
          ),
        );
      }
    }
  }

  Future<void> _handleAppleTap(BuildContext context, WidgetRef ref) async {
    if (appleId != null) {
      if (_authMethodCount() <= 1) {
        AppToast.error(context, context.l10n.profileLastAuthMethodRequired);
        return;
      }
      final confirmed = await _confirmDisconnect(
        context,
        provider: context.l10n.profileConnectedAccountsApple,
        includeSteamWarning: false,
      );
      if (confirmed != true || !context.mounted) return;
      try {
        await ref.read(profileRepositoryProvider).unlinkApple();
        _refreshProviders(ref);
        if (context.mounted) {
          AppToast.success(
            context,
            context.l10n.profileDisconnectedSuccess(
              context.l10n.profileConnectedAccountsApple,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.error(
            context,
            context.l10n.profileDisconnectFailed(
              context.l10n.profileConnectedAccountsApple,
              ApiError.userMessage(e, context.l10n),
            ),
          );
        }
      }
    } else {
      try {
        final appleSignIn = await OAuthLauncher.launchAppleSignIn();
        if (!context.mounted) return;
        await ref
            .read(profileRepositoryProvider)
            .linkApple(appleSignIn.identityToken);
        _refreshProviders(ref);
        if (context.mounted) {
          AppToast.success(context, context.l10n.profileAppleLinkedSuccess);
        }
      } on SignInWithAppleAuthorizationException catch (e) {
        if (e.code == AuthorizationErrorCode.canceled) return;
        debugPrint('Apple link auth exception: code=${e.code} message=$e');
        if (context.mounted) {
          AppToast.error(context, context.l10n.profileAppleSignInFailed);
        }
      } catch (e) {
        if (!context.mounted) return;
        AppToast.error(
          context,
          context.l10n.profileLinkAppleFailed(
            ApiError.userMessage(e, context.l10n),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steamConnected = steamId != null;
    final appleConnected = appleId != null;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: context.l10n.profileSectionConnectedAccounts),
          const SizedBox(height: AppSpacing.md),
          _AccountRow(
            icon: Icons.email_outlined,
            label: context.l10n.profileConnectedAccountsEmailPassword,
            connected: hasPasswordLogin,
            onTap: hasPasswordLogin
                ? null
                : () => _handleEmailTap(context, ref),
          ),
          Divider(
            color: AppColors.glassBorder.withValues(alpha: 0.4),
            height: 1,
          ),
          _AccountRow(
            icon: Icons.gamepad_outlined,
            label: context.l10n.profileConnectedAccountsSteam,
            connected: steamConnected,
            statusText: steamConnected
                ? context.l10n.profileConnectedTapToDisconnect
                : null,
            onTap: () => _handleSteamTap(context, ref),
          ),
          Divider(
            color: AppColors.glassBorder.withValues(alpha: 0.4),
            height: 1,
          ),
          _AccountRow(
            icon: Icons.apple,
            label: context.l10n.profileConnectedAccountsApple,
            connected: appleConnected,
            statusText: appleConnected
                ? context.l10n.profileConnectedTapToDisconnect
                : null,
            onTap: () => _handleAppleTap(context, ref),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.connected,
    this.statusText,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool connected;
  final String? statusText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: connected
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.glassSurfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: connected ? AppColors.success : AppColors.textTertiary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText ??
                        (connected
                            ? context.l10n.profileConnected
                            : context.l10n.profileNotConnected),
                    style: TextStyle(
                      color: connected
                          ? AppColors.success
                          : AppColors.textTertiary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary.withValues(alpha: 0.5),
                size: 20,
              )
            else if (connected)
              const Icon(Icons.check_circle, color: AppColors.success, size: 20)
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}

class _SetEmailPasswordDialog extends StatefulWidget {
  const _SetEmailPasswordDialog();

  @override
  State<_SetEmailPasswordDialog> createState() =>
      _SetEmailPasswordDialogState();
}

class _SetEmailPasswordDialogState extends State<_SetEmailPasswordDialog>
    with LocaleAwareFormStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _hasAttemptedSubmit = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    _hasAttemptedSubmit = true;
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      email: _emailController.text.trim(),
      password: _passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    revalidateFormOnLocaleChange(
      formKey: _formKey,
      shouldRevalidate: _hasAttemptedSubmit,
    );

    return AlertDialog(
      backgroundColor: AppColors.backgroundLight,
      title: Text(l10n.profileSetEmailPasswordTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.profileSetEmailPasswordDescription,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.loginEmailLabel,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.validatorEmailRequired;
                }
                if (!v.contains('@') || !v.contains('.')) {
                  return l10n.validatorEmailInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: l10n.loginPasswordLabel,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 8) {
                  return l10n.validatorPasswordMin;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: l10n.registerConfirmPasswordLabel,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: (v) {
                if (v != _passwordController.text) {
                  return l10n.validatorPasswordsMismatch;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.commonAdd)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.glassSurfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.textTertiary),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
