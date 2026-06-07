import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/provider_visuals.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/weekly_availability_editor.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_list_row.dart';
import '../../../../shared/services/app_haptics.dart';

import '../../../auth/data/oauth_launcher.dart';
import '../../../auth/domain/provider_identity_model.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/profile_repository.dart';
import '../providers/profile_provider.dart';

bool _isValidPlayStationShareLink(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  return uri != null &&
      uri.hasScheme &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      (uri.host == 'playstation.com' || uri.host.endsWith('.playstation.com'));
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return AppBackgroundSurface(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: context.l10n.profileTitle,
          contentWidth: DesktopContentWidth.reading,
        ),
        body: profileAsync.when(
          loading: () => const DesktopContentRegion(
            width: DesktopContentWidth.reading,
            child: Center(child: LoadingIndicator()),
          ),
          error: (error, _) => DesktopContentRegion(
            width: DesktopContentWidth.reading,
            child: ErrorDisplay(
              message: ApiError.userMessage(error, context.l10n),
              onRetry: () => ref.read(profileNotifierProvider.notifier).load(),
            ),
          ),
          data: (user) {
            if (user == null) {
              return DesktopContentRegion(
                width: DesktopContentWidth.reading,
                child: ErrorDisplay(
                  message: context.l10n.profileLoadError,
                  onRetry: () =>
                      ref.read(profileNotifierProvider.notifier).load(),
                ),
              );
            }

            return DesktopContentRegion(
              width: DesktopContentWidth.reading,
              child: SingleChildScrollView(
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
                      providerIdentities: user.providerIdentities,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SocialIdentitiesCard(
                      steamId: user.steamId,
                      providerIdentities: user.providerIdentities,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GlassButton(
                      onPressed: () => context.goNamed(RouteNames.editProfile),
                      child: Text(context.l10n.profileEdit),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GlassButton(
                      variant: GlassButtonVariant.ghost,
                      onPressed: () => _confirmLogout(context, ref),
                      child: Text(
                        context.l10n.profileLogout,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: context.l10n.profileLogoutConfirmTitle,
      message: context.l10n.profileLogoutConfirmMessage,
      confirmLabel: context.l10n.profileLogout,
      cancelLabel: context.l10n.commonCancel,
      variant: AppConfirmationVariant.destructive,
    );
    if (!confirmed) return;

    await ref.read(authNotifierProvider.notifier).logout();
    await ref.read(appHapticsProvider).destructiveConfirm();
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

class _AccountInfoCard extends ConsumerWidget {
  const _AccountInfoCard({required this.user});

  final User user;

  static String _formatDate(DateTime date) {
    return DateFormat.yMMMd(Intl.getCurrentLocale()).format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = [
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
          _InfoRow(
            icon: Icons.email_outlined,
            label: context.l10n.profileEmailLabel,
            value: user.email ?? context.l10n.profileNotSet,
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 18,
            ),
            onTap: () async {
              final result = await showDialog<String>(
                context: context,
                useRootNavigator: true,
                builder: (context) =>
                    _ChangeEmailDialog(initialEmail: user.email?.trim()),
              );
              if (result == null || !context.mounted) return;

              await ref.read(profileNotifierProvider.notifier).updateProfile({
                'email': result,
              });
              if (!context.mounted) return;

              final profileState = ref.read(profileNotifierProvider);
              if (profileState.hasError) {
                AppToast.error(
                  context,
                  context.l10n.profileChangeEmailFailed(
                    ApiError.userMessage(profileState.error!, context.l10n),
                  ),
                );
                return;
              }

              ref.invalidate(authNotifierProvider);
              AppToast.success(context, context.l10n.profileChangeEmailSuccess);
              await ref.read(appHapticsProvider).success();
            },
          ),
          for (var i = 0; i < rows.length; i++) ...[
            const Divider(height: 1),
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

  String _readableTime(BuildContext context, String t) {
    final parts = t.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: hour, minute: minute),
      alwaysUse24HourFormat:
          MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
    );
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
              return '${_readableTime(context, parts[0])} – ${_readableTime(context, parts[1])}';
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
                  child: Divider(height: 1),
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
    return AppChip.accent(label: label, icon: icon, color: AppColors.primary);
  }
}

class _ConnectedAccountsCard extends ConsumerWidget {
  const _ConnectedAccountsCard({
    this.email,
    required this.hasPasswordLogin,
    this.steamId,
    this.appleId,
    required this.providerIdentities,
  });

  final String? email;
  final bool hasPasswordLogin;
  final String? steamId;
  final String? appleId;
  final List<ProviderIdentity> providerIdentities;

  int _authMethodCount() {
    var count = 0;
    if (hasPasswordLogin) count++;
    for (final identity in providerIdentities) {
      if (identity.supportsLogin) count++;
    }
    if (steamId != null && _identityFor('steam')?.externalId == null) {
      count++;
    }
    if (appleId != null && _identityFor('apple')?.externalId == null) {
      count++;
    }
    return count;
  }

  ProviderIdentity? _identityFor(String provider) {
    for (final identity in providerIdentities) {
      if (identity.provider == provider) {
        return identity;
      }
    }
    if (provider == 'steam' && steamId != null) {
      return const ProviderIdentity(
        provider: 'steam',
        authMode: 'official_openid',
        displayName: null,
        supportsLogin: true,
        supportsRefresh: true,
        supportsDirectProfileLink: true,
        supportsManualEntry: false,
        supportsCopyOnlyAction: false,
        isSocialIdentity: true,
      );
    }
    if (provider == 'apple' && appleId != null) {
      return const ProviderIdentity(
        provider: 'apple',
        authMode: 'official_oauth',
        supportsLogin: true,
        supportsRefresh: false,
        supportsDirectProfileLink: false,
        supportsManualEntry: false,
        supportsCopyOnlyAction: false,
        isSocialIdentity: false,
      );
    }
    return null;
  }

  String? _identityStatus(ProviderIdentity? identity) {
    if (identity == null) return null;
    return identity.displayName ??
        identity.username ??
        (identity.provider == 'apple' ? null : identity.externalId) ??
        (identity.supportsLogin
            ? currentAppLocalizations().profileConnectedTapToDisconnect
            : currentAppLocalizations().profileConnected);
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
    final steamIdentity = _identityFor('steam');
    if (steamIdentity != null) {
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
        await ref.read(appHapticsProvider).destructiveConfirm();
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
        await ref.read(appHapticsProvider).success();
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
    final currentEmail = email?.trim();
    if (currentEmail == null || currentEmail.isEmpty) {
      AppToast.error(context, context.l10n.profileAddEmailFirst);
      return;
    }

    final result = await showDialog<({String email, String password})>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _SetEmailPasswordDialog(email: currentEmail),
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
      await ref.read(appHapticsProvider).success();
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

  Future<void> _handleDiscordTap(BuildContext context, WidgetRef ref) async {
    final discordIdentity = _identityFor('discord');
    if (discordIdentity != null) {
      if (_authMethodCount() <= 1) {
        AppToast.error(context, context.l10n.profileLastAuthMethodRequired);
        return;
      }
      final confirmed = await _confirmDisconnect(
        context,
        provider: context.l10n.profileConnectedAccountsDiscord,
        includeSteamWarning: false,
      );
      if (confirmed != true || !context.mounted) return;
      try {
        await ref.read(profileRepositoryProvider).unlinkDiscord();
        _refreshProviders(ref);
        if (context.mounted) {
          AppToast.success(
            context,
            context.l10n.profileDisconnectedSuccess(
              context.l10n.profileConnectedAccountsDiscord,
            ),
          );
        }
        await ref.read(appHapticsProvider).destructiveConfirm();
      } catch (e) {
        if (context.mounted) {
          AppToast.error(
            context,
            context.l10n.profileDisconnectFailed(
              context.l10n.profileConnectedAccountsDiscord,
              ApiError.userMessage(e, context.l10n),
            ),
          );
        }
      }
    } else {
      final DiscordAuthResult? discordAuthResult;
      try {
        discordAuthResult = await OAuthLauncher.launchDiscordAuth();
      } catch (e) {
        if (!context.mounted || OAuthLauncher.isCancellationError(e)) return;
        AppToast.error(
          context,
          OAuthLauncher.toFailure(e).userMessage(context.l10n),
        );
        return;
      }

      if (!context.mounted) return;
      try {
        await ref
            .read(profileRepositoryProvider)
            .linkDiscord(
              code: discordAuthResult.code,
              codeVerifier: discordAuthResult.codeVerifier,
              redirectUri: discordAuthResult.redirectUri,
            );
        _refreshProviders(ref);
        if (context.mounted) {
          AppToast.success(context, context.l10n.profileDiscordLinkedSuccess);
        }
        await ref.read(appHapticsProvider).success();
      } catch (e) {
        if (!context.mounted) return;
        AppToast.error(
          context,
          context.l10n.profileLinkDiscordFailed(
            ApiError.userMessage(e, context.l10n),
          ),
        );
      }
    }
  }

  Future<void> _handleAppleTap(BuildContext context, WidgetRef ref) async {
    final appleIdentity = _identityFor('apple');
    if (appleIdentity != null) {
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
        await ref.read(appHapticsProvider).destructiveConfirm();
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
      final AppleSignInResult? appleSignInResult;
      try {
        appleSignInResult = await OAuthLauncher.launchAppleSignIn();
      } catch (e) {
        if (!context.mounted || OAuthLauncher.isCancellationError(e)) return;
        AppToast.error(
          context,
          OAuthLauncher.toFailure(e).userMessage(context.l10n),
        );
        return;
      }

      if (!context.mounted) return;

      try {
        await ref
            .read(profileRepositoryProvider)
            .linkApple(appleSignInResult.identityToken);
        _refreshProviders(ref);
        if (context.mounted) {
          AppToast.success(context, context.l10n.profileAppleLinkedSuccess);
        }
        await ref.read(appHapticsProvider).success();
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
    final steamIdentity = _identityFor('steam');
    final discordIdentity = _identityFor('discord');
    final appleIdentity = _identityFor('apple');
    final steamConnected = steamIdentity != null;
    final discordConnected = discordIdentity != null;
    final appleConnected = appleIdentity != null;
    final showDiscordRow =
        discordConnected || OAuthLauncher.discordSignInAvailable;
    final showAppleRow = appleConnected || OAuthLauncher.appleSignInAvailable;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: context.l10n.profileSectionConnectedAccounts),
          const SizedBox(height: AppSpacing.md),
          _AccountRow(
            icon: ProviderVisuals.email.icon,
            label: context.l10n.profileConnectedAccountsEmailPassword,
            connected: hasPasswordLogin,
            iconColor: ProviderVisuals.rowIconColor(
              'email',
              connected: hasPasswordLogin,
            ),
            iconBackgroundColor: ProviderVisuals.rowIconBackground(
              'email',
              connected: hasPasswordLogin,
            ),
            onTap: hasPasswordLogin
                ? null
                : () => _handleEmailTap(context, ref),
          ),
          const Divider(height: 1),
          _AccountRow(
            icon: ProviderVisuals.steam.icon,
            label: context.l10n.profileConnectedAccountsSteam,
            connected: steamConnected,
            iconColor: ProviderVisuals.rowIconColor(
              'steam',
              connected: steamConnected,
            ),
            iconBackgroundColor: ProviderVisuals.rowIconBackground(
              'steam',
              connected: steamConnected,
            ),
            statusText: _identityStatus(steamIdentity),
            onTap: () => _handleSteamTap(context, ref),
          ),
          if (showDiscordRow) ...[
            const Divider(height: 1),
            _AccountRow(
              icon: ProviderVisuals.discord.icon,
              label: context.l10n.profileConnectedAccountsDiscord,
              connected: discordConnected,
              iconColor: ProviderVisuals.rowIconColor(
                'discord',
                connected: discordConnected,
              ),
              iconBackgroundColor: ProviderVisuals.rowIconBackground(
                'discord',
                connected: discordConnected,
              ),
              statusText: _identityStatus(discordIdentity),
              onTap: () => _handleDiscordTap(context, ref),
            ),
          ],
          if (showAppleRow) ...[
            const Divider(height: 1),
            _AccountRow(
              icon: ProviderVisuals.apple.icon,
              label: context.l10n.profileConnectedAccountsApple,
              connected: appleConnected,
              iconColor: ProviderVisuals.rowIconColor(
                'apple',
                connected: appleConnected,
              ),
              iconBackgroundColor: ProviderVisuals.rowIconBackground(
                'apple',
                connected: appleConnected,
              ),
              statusText: _identityStatus(appleIdentity),
              onTap: () => _handleAppleTap(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialIdentitiesCard extends ConsumerWidget {
  const _SocialIdentitiesCard({this.steamId, required this.providerIdentities});

  final String? steamId;
  final List<ProviderIdentity> providerIdentities;

  ProviderIdentity? _identityFor(String provider) {
    for (final identity in providerIdentities) {
      if (identity.provider == provider) {
        return identity;
      }
    }
    if (provider == 'steam' && steamId != null) {
      return const ProviderIdentity(
        provider: 'steam',
        authMode: 'official_openid',
        supportsLogin: true,
        supportsRefresh: true,
        supportsDirectProfileLink: true,
        supportsManualEntry: false,
        supportsCopyOnlyAction: false,
        isSocialIdentity: true,
      );
    }
    return null;
  }

  String _providerLabel(BuildContext context, String provider) {
    return switch (provider) {
      'steam' => context.l10n.profileConnectedAccountsSteam,
      'discord' => context.l10n.profileConnectedAccountsDiscord,
      'xbox' => context.l10n.profileConnectedAccountsXbox,
      'playstation' => context.l10n.profileConnectedAccountsPlayStation,
      'nintendo' => context.l10n.profileConnectedAccountsNintendo,
      _ => provider,
    };
  }

  String _identityStatus(
    BuildContext context, {
    required String provider,
    required ProviderIdentity? identity,
  }) {
    if (identity == null) {
      if (provider == 'steam' || provider == 'discord') {
        return context.l10n.profileSocialIdentityLinkInConnectedAccounts;
      }
      return context.l10n.profileNotConnected;
    }

    return identity.displayName ??
        identity.username ??
        (identity.metadata?['friend_code'] as String?) ??
        identity.externalId ??
        context.l10n.profileConnected;
  }

  String? _socialProfileUrl(ProviderIdentity? identity) {
    final profileUrl = identity?.profileUrl?.trim();
    if (profileUrl == null || profileUrl.isEmpty) return null;
    return profileUrl;
  }

  String? _generatedXboxProfileUrl(ProviderIdentity? identity) {
    final gamertag = identity?.username?.trim() ?? identity?.externalId?.trim();
    if (gamertag == null || gamertag.isEmpty) return null;
    return 'https://account.xbox.com/en-us/profile?gamertag=${Uri.encodeComponent(gamertag)}';
  }

  String? _nintendoFriendCode(ProviderIdentity? identity) {
    final friendCode =
        (identity?.metadata?['friend_code'] as String?)?.trim() ??
        identity?.externalId?.trim();
    if (friendCode == null || friendCode.isEmpty) return null;
    return friendCode;
  }

  Future<void> _openSocialProfile(
    BuildContext context, {
    required String provider,
    required String profileUrl,
  }) async {
    final uri = Uri.tryParse(profileUrl);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        (provider == 'playstation' &&
            !_isValidPlayStationShareLink(profileUrl))) {
      AppToast.error(
        context,
        context.l10n.profileSocialIdentityOpenFailed(
          _providerLabel(context, provider),
        ),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppToast.error(
          context,
          context.l10n.profileSocialIdentityOpenFailed(
            _providerLabel(context, provider),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        context.l10n.profileSocialIdentityOpenFailed(
          _providerLabel(context, provider),
        ),
      );
    }
  }

  Future<void> _copySocialValue(
    BuildContext context, {
    required String provider,
    required String value,
  }) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (!context.mounted) return;
      AppToast.success(
        context,
        context.l10n.profileSocialIdentityCopiedSuccess(
          _providerLabel(context, provider),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        context.l10n.profileSocialIdentityCopyFailed(
          _providerLabel(context, provider),
        ),
      );
    }
  }

  Future<void> _handleManualSocialTap(
    BuildContext context,
    WidgetRef ref, {
    required String provider,
  }) async {
    final identity = _identityFor(provider);
    if (identity == null) {
      await _handleManualIdentityTap(context, ref, provider: provider);
      return;
    }

    switch (provider) {
      case 'xbox':
        final profileUrl =
            _socialProfileUrl(identity) ?? _generatedXboxProfileUrl(identity);
        if (profileUrl == null) {
          if (!context.mounted) return;
          AppToast.error(
            context,
            context.l10n.profileSocialIdentityOpenFailed(
              _providerLabel(context, provider),
            ),
          );
          return;
        }
        await _openSocialProfile(
          context,
          provider: provider,
          profileUrl: profileUrl,
        );
        return;
      case 'playstation':
        final profileUrl = _socialProfileUrl(identity);
        if (profileUrl == null) {
          if (!context.mounted) return;
          AppToast.error(
            context,
            context.l10n.profileSocialIdentityOpenFailed(
              _providerLabel(context, provider),
            ),
          );
          return;
        }
        await _openSocialProfile(
          context,
          provider: provider,
          profileUrl: profileUrl,
        );
        return;
      case 'nintendo':
        final friendCode = _nintendoFriendCode(identity);
        if (friendCode == null) {
          if (!context.mounted) return;
          AppToast.error(
            context,
            context.l10n.profileSocialIdentityCopyFailed(
              _providerLabel(context, provider),
            ),
          );
          return;
        }
        await _copySocialValue(context, provider: provider, value: friendCode);
        return;
      default:
        await _handleManualIdentityTap(context, ref, provider: provider);
        return;
    }
  }

  Widget? _manualSocialTrailing(
    BuildContext context, {
    required String provider,
    required ProviderIdentity? identity,
    required VoidCallback onEdit,
  }) {
    if (identity == null) return null;

    final actionIcon = switch (provider) {
      'nintendo' => Icons.copy_outlined,
      _ => Icons.chevron_right,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          actionIcon,
          color: AppColors.textTertiary.withValues(alpha: 0.5),
          size: 20,
        ),
        IconButton(
          tooltip: context.l10n.commonEdit,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          color: AppColors.textTertiary,
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          splashRadius: 18,
        ),
      ],
    );
  }

  void _refreshProviders(WidgetRef ref) {
    ref.read(profileNotifierProvider.notifier).load();
    ref.invalidate(authNotifierProvider);
  }

  Future<void> _handleManualIdentityTap(
    BuildContext context,
    WidgetRef ref, {
    required String provider,
  }) async {
    final existing = _identityFor(provider);
    final result = await showDialog<_ManualSocialIdentityDialogResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _ManualSocialIdentityDialog(
        provider: provider,
        label: _providerLabel(context, provider),
        existing: existing,
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      if (result.remove) {
        await ref
            .read(profileRepositoryProvider)
            .deleteManualSocialIdentity(provider);
        _refreshProviders(ref);
        if (context.mounted) {
          AppToast.success(
            context,
            context.l10n.profileSocialIdentityRemovedSuccess(
              _providerLabel(context, provider),
            ),
          );
        }
        await ref.read(appHapticsProvider).destructiveConfirm();
        return;
      }

      await ref
          .read(profileRepositoryProvider)
          .upsertManualSocialIdentity(
            provider: provider,
            externalId: result.externalId,
            username: result.username,
            displayName: result.displayName,
            profileUrl: result.profileUrl,
          );
      _refreshProviders(ref);
      if (context.mounted) {
        AppToast.success(
          context,
          context.l10n.profileSocialIdentitySavedSuccess(
            _providerLabel(context, provider),
          ),
        );
      }
      await ref.read(appHapticsProvider).success();
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        context.l10n.profileSocialIdentitySaveFailed(
          _providerLabel(context, provider),
          ApiError.userMessage(e, context.l10n),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steamIdentity = _identityFor('steam');
    final discordIdentity = _identityFor('discord');
    final xboxIdentity = _identityFor('xbox');
    final playStationIdentity = _identityFor('playstation');
    final nintendoIdentity = _identityFor('nintendo');
    final steamProfileUrl = _socialProfileUrl(steamIdentity);
    final discordProfileUrl = _socialProfileUrl(discordIdentity);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: context.l10n.profileSectionSocials),
          const SizedBox(height: AppSpacing.md),
          if (steamIdentity != null) ...[
            _AccountRow(
              icon: ProviderVisuals.steam.icon,
              label: context.l10n.profileConnectedAccountsSteam,
              connected: true,
              iconColor: ProviderVisuals.rowIconColor('steam', connected: true),
              iconBackgroundColor: ProviderVisuals.rowIconBackground(
                'steam',
                connected: true,
              ),
              statusText: _identityStatus(
                context,
                provider: 'steam',
                identity: steamIdentity,
              ),
              onTap: steamProfileUrl == null
                  ? null
                  : () => _openSocialProfile(
                      context,
                      provider: 'steam',
                      profileUrl: steamProfileUrl,
                    ),
            ),
            const Divider(height: 1),
          ],
          if (discordIdentity != null) ...[
            _AccountRow(
              icon: ProviderVisuals.discord.icon,
              label: context.l10n.profileConnectedAccountsDiscord,
              connected: true,
              iconColor: ProviderVisuals.rowIconColor(
                'discord',
                connected: true,
              ),
              iconBackgroundColor: ProviderVisuals.rowIconBackground(
                'discord',
                connected: true,
              ),
              statusText: _identityStatus(
                context,
                provider: 'discord',
                identity: discordIdentity,
              ),
              onTap: discordProfileUrl == null
                  ? null
                  : () => _openSocialProfile(
                      context,
                      provider: 'discord',
                      profileUrl: discordProfileUrl,
                    ),
            ),
            const Divider(height: 1),
          ],
          _AccountRow(
            icon: ProviderVisuals.xbox.icon,
            label: context.l10n.profileConnectedAccountsXbox,
            connected: xboxIdentity != null,
            iconColor: ProviderVisuals.rowIconColor(
              'xbox',
              connected: xboxIdentity != null,
            ),
            iconBackgroundColor: ProviderVisuals.rowIconBackground(
              'xbox',
              connected: xboxIdentity != null,
            ),
            statusText: _identityStatus(
              context,
              provider: 'xbox',
              identity: xboxIdentity,
            ),
            trailing: _manualSocialTrailing(
              context,
              provider: 'xbox',
              identity: xboxIdentity,
              onEdit: () {
                _handleManualIdentityTap(context, ref, provider: 'xbox');
              },
            ),
            onTap: () => _handleManualSocialTap(context, ref, provider: 'xbox'),
          ),
          const Divider(height: 1),
          _AccountRow(
            icon: ProviderVisuals.playstation.icon,
            label: context.l10n.profileConnectedAccountsPlayStation,
            connected: playStationIdentity != null,
            iconColor: ProviderVisuals.rowIconColor(
              'playstation',
              connected: playStationIdentity != null,
            ),
            iconBackgroundColor: ProviderVisuals.rowIconBackground(
              'playstation',
              connected: playStationIdentity != null,
            ),
            statusText: _identityStatus(
              context,
              provider: 'playstation',
              identity: playStationIdentity,
            ),
            trailing: _manualSocialTrailing(
              context,
              provider: 'playstation',
              identity: playStationIdentity,
              onEdit: () {
                _handleManualIdentityTap(context, ref, provider: 'playstation');
              },
            ),
            onTap: () =>
                _handleManualSocialTap(context, ref, provider: 'playstation'),
          ),
          const Divider(height: 1),
          _AccountRow(
            icon: ProviderVisuals.nintendo.icon,
            label: context.l10n.profileConnectedAccountsNintendo,
            connected: nintendoIdentity != null,
            iconColor: ProviderVisuals.rowIconColor(
              'nintendo',
              connected: nintendoIdentity != null,
            ),
            iconBackgroundColor: ProviderVisuals.rowIconBackground(
              'nintendo',
              connected: nintendoIdentity != null,
            ),
            statusText: _identityStatus(
              context,
              provider: 'nintendo',
              identity: nintendoIdentity,
            ),
            trailing: _manualSocialTrailing(
              context,
              provider: 'nintendo',
              identity: nintendoIdentity,
              onEdit: () {
                _handleManualIdentityTap(context, ref, provider: 'nintendo');
              },
            ),
            onTap: () =>
                _handleManualSocialTap(context, ref, provider: 'nintendo'),
          ),
        ],
      ),
    );
  }
}

class _ManualSocialIdentityDialogResult {
  const _ManualSocialIdentityDialogResult({
    this.remove = false,
    this.externalId,
    this.username,
    this.displayName,
    this.profileUrl,
  });

  final bool remove;
  final String? externalId;
  final String? username;
  final String? displayName;
  final String? profileUrl;
}

class _ManualSocialIdentityDialog extends StatefulWidget {
  const _ManualSocialIdentityDialog({
    required this.provider,
    required this.label,
    required this.existing,
  });

  final String provider;
  final String label;
  final ProviderIdentity? existing;

  @override
  State<_ManualSocialIdentityDialog> createState() =>
      _ManualSocialIdentityDialogState();
}

class _ManualSocialIdentityDialogState
    extends State<_ManualSocialIdentityDialog>
    with LocaleAwareFormStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _primaryController;
  late final TextEditingController _secondaryController;
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    _primaryController = TextEditingController(text: _initialPrimaryValue());
    _secondaryController = TextEditingController(
      text: _initialSecondaryValue(),
    );
  }

  String _initialPrimaryValue() {
    return switch (widget.provider) {
      'xbox' => widget.existing?.username ?? widget.existing?.externalId ?? '',
      'playstation' => widget.existing?.profileUrl ?? '',
      'nintendo' =>
        (widget.existing?.metadata?['friend_code'] as String?) ??
            widget.existing?.externalId ??
            '',
      _ => '',
    };
  }

  String _initialSecondaryValue() {
    return switch (widget.provider) {
      'playstation' => widget.existing?.username ?? '',
      'nintendo' => widget.existing?.displayName ?? '',
      _ => '',
    };
  }

  String _primaryLabel(BuildContext context) {
    return switch (widget.provider) {
      'xbox' => context.l10n.profileSocialIdentityGamertagLabel,
      'playstation' => context.l10n.profileSocialIdentityShareLinkLabel,
      'nintendo' => context.l10n.profileSocialIdentityFriendCodeLabel,
      _ => widget.label,
    };
  }

  String? _secondaryLabel(BuildContext context) {
    return switch (widget.provider) {
      'playstation' => context.l10n.profileSocialIdentityOnlineIdLabel,
      'nintendo' => context.l10n.profileSocialIdentityNicknameLabel,
      _ => null,
    };
  }

  void _submit() {
    _hasAttemptedSubmit = true;
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _ManualSocialIdentityDialogResult(
        externalId: switch (widget.provider) {
          'xbox' => _primaryController.text.trim(),
          'nintendo' => _primaryController.text.trim(),
          _ => null,
        },
        username: switch (widget.provider) {
          'xbox' => _primaryController.text.trim(),
          'playstation' =>
            _secondaryController.text.trim().isEmpty
                ? null
                : _secondaryController.text.trim(),
          _ => null,
        },
        displayName: switch (widget.provider) {
          'nintendo' =>
            _secondaryController.text.trim().isEmpty
                ? null
                : _secondaryController.text.trim(),
          _ => null,
        },
        profileUrl: switch (widget.provider) {
          'playstation' => _primaryController.text.trim(),
          _ => null,
        },
      ),
    );
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    revalidateFormOnLocaleChange(
      formKey: _formKey,
      shouldRevalidate: _hasAttemptedSubmit,
    );

    final existing = widget.existing;
    final secondaryLabel = _secondaryLabel(context);
    return AlertDialog(
      title: Text(
        existing == null
            ? context.l10n.profileSocialIdentityAddTitle(widget.label)
            : context.l10n.profileSocialIdentityEditTitle(widget.label),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _primaryController,
              decoration: InputDecoration(labelText: _primaryLabel(context)),
              validator: (value) {
                final trimmed = (value ?? '').trim();
                if (trimmed.isEmpty) {
                  return context.l10n.validatorFieldRequired(
                    _primaryLabel(context),
                  );
                }
                if (widget.provider == 'playstation') {
                  if (!_isValidPlayStationShareLink(trimmed)) {
                    return context.l10n.profileSocialIdentityInvalidShareLink;
                  }
                }
                return null;
              },
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _secondaryController,
                decoration: InputDecoration(labelText: secondaryLabel),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        if (existing != null)
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(const _ManualSocialIdentityDialogResult(remove: true)),
            child: Text(
              context.l10n.commonRemove,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        TextButton(onPressed: _submit, child: Text(context.l10n.commonSave)),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.connected,
    this.statusText,
    this.iconColor,
    this.iconBackgroundColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool connected;
  final String? statusText;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? trailing;
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
                color:
                    iconBackgroundColor ??
                    (connected
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.glassSurfaceLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color:
                    iconColor ??
                    (connected ? AppColors.success : AppColors.textTertiary),
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
            if (trailing != null)
              trailing!
            else if (onTap != null)
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
  const _SetEmailPasswordDialog({required this.email});

  final String email;

  @override
  State<_SetEmailPasswordDialog> createState() =>
      _SetEmailPasswordDialogState();
}

class _SetEmailPasswordDialogState extends State<_SetEmailPasswordDialog>
    with LocaleAwareFormStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _hasAttemptedSubmit = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    _hasAttemptedSubmit = true;
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop((email: widget.email, password: _passwordController.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    revalidateFormOnLocaleChange(
      formKey: _formKey,
      shouldRevalidate: _hasAttemptedSubmit,
    );

    return AlertDialog(
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
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.glassSurfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.profileEmailLabel,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.email,
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
              ),
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

class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog({this.initialEmail});

  final String? initialEmail;

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog>
    with LocaleAwareFormStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    _hasAttemptedSubmit = true;
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    revalidateFormOnLocaleChange(
      formKey: _formKey,
      shouldRevalidate: _hasAttemptedSubmit,
    );

    return AlertDialog(
      title: Text(l10n.profileChangeEmailTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.profileChangeEmailDescription,
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.commonSave)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppListRow(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      gap: AppSpacing.sm + 4,
      onTap: onTap,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.glassSurfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.textTertiary),
      ),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
    );
  }
}
