import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/localization/locale_aware_form_state_mixin.dart';
import '../../../../core/networking/api_error.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../../../shared/widgets/editable_avatar_field.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/app_popup_menu_button.dart';
import '../../../../shared/widgets/provider_visuals.dart';
import '../../../../shared/widgets/social_identities_card.dart';
import '../../../../shared/widgets/gaming_hours_display.dart';
import '../../../../shared/widgets/app_list_row.dart';
import '../../../../shared/widgets/tappable.dart';
import '../../../../shared/services/app_haptics.dart';
import '../../../../shared/utils/social_identity_helpers.dart';

import '../../../auth/data/oauth_launcher.dart';
import '../../../auth/domain/provider_identity_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_settings_editors.dart';

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

enum _SocialRowAction { edit, remove }

Future<bool> _saveProfileUpdates(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, dynamic> updates,
  String? successMessage,
}) async {
  try {
    await ref.read(profileNotifierProvider.notifier).updateProfile(updates);
  } catch (error) {
    if (!context.mounted) return false;
    AppToast.error(context, ApiError.userMessage(error, context.l10n));
    return false;
  }

  if (!context.mounted) return false;
  if (successMessage != null && successMessage.isNotEmpty) {
    AppToast.success(context, successMessage);
  }
  await ref.read(appHapticsProvider).success();
  return true;
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBlockingLoad = ref.watch(
      profileNotifierProvider.select(
        (state) => state.isLoading && !state.hasValue,
      ),
    );
    final blockingError = ref.watch(
      profileNotifierProvider.select(
        (state) => !state.hasValue ? state.error : null,
      ),
    );
    final hasProfileUser = ref.watch(
      profileNotifierProvider.select((state) => state.hasValue),
    );

    return AppBackgroundSurface(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: context.l10n.profileTitle,
          contentWidth: DesktopContentWidth.reading,
        ),
        body: isBlockingLoad
            ? const DesktopContentRegion(
                width: DesktopContentWidth.reading,
                child: Center(child: LoadingIndicator()),
              )
            : !hasProfileUser
            ? DesktopContentRegion(
                width: DesktopContentWidth.reading,
                child: ErrorDisplay(
                  message: blockingError != null
                      ? ApiError.userMessage(blockingError, context.l10n)
                      : context.l10n.profileLoadError,
                  onRetry: () =>
                      ref.read(profileNotifierProvider.notifier).load(),
                ),
              )
            : DesktopContentRegion(
                width: DesktopContentWidth.reading,
                child: AppRefreshIndicator(
                  onRefresh: () =>
                      ref.read(profileNotifierProvider.notifier).load(),
                  child: const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeaderSection(),
                        SizedBox(height: AppSpacing.xl),
                        _AccountInfoCard(),
                        SizedBox(height: AppSpacing.md),
                        _PreferencesCard(),
                        SizedBox(height: AppSpacing.md),
                        _GamingHoursCard(),
                        SizedBox(height: AppSpacing.md),
                        _ConnectedAccountsCard(),
                        SizedBox(height: AppSpacing.md),
                        _SocialIdentitiesCard(),
                        SizedBox(height: AppSpacing.xl),
                        _ProfileActions(),
                      ],
                    ),
                  ),
                ),
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

class _ProfileHeaderSection extends ConsumerWidget {
  const _ProfileHeaderSection();

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref, {
    required String displayName,
  }) async {
    await showProfileSettingsEditor<void>(
      context: context,
      builder: (_) => ProfileTextValueEditor(
        title: context.l10n.profileEditDisplayNameTitle,
        label: context.l10n.registerDisplayNameLabel,
        initialValue: displayName,
        hint: context.l10n.editProfileDisplayNameHint,
        validator: FormValidators.displayName,
        onSubmitted: (value) =>
            _saveProfileUpdates(context, ref, updates: {'display_name': value}),
      ),
    );
  }

  Future<void> _editBio(
    BuildContext context,
    WidgetRef ref, {
    required String bio,
  }) async {
    await showProfileSettingsEditor<void>(
      context: context,
      builder: (_) => ProfileTextValueEditor(
        title: context.l10n.profileEditBioTitle,
        label: context.l10n.editProfileBioLabel,
        initialValue: bio,
        hint: context.l10n.editProfileBioHint,
        maxLines: 3,
        onSubmitted: (value) =>
            _saveProfileUpdates(context, ref, updates: {'bio': value}),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final header = ref.watch(
      profileUserProvider.select(
        (user) => (
          avatarUrl: user?.avatarUrl,
          bio: user?.bio,
          displayName: user?.displayName ?? '',
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        Center(
          child: EditableAvatarField(
            initialAvatarUrl: header.avatarUrl,
            displayName: header.displayName,
            size: 96,
            onChanged: (value) async {
              await _saveProfileUpdates(
                context,
                ref,
                updates: {'avatar_url': value},
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Tappable(
            onTap: () =>
                _editDisplayName(context, ref, displayName: header.displayName),
            child: Text(
              header.displayName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Tappable(
            onTap: () => _editBio(context, ref, bio: header.bio ?? ''),
            child: Text(
              header.bio?.isNotEmpty == true
                  ? header.bio!
                  : context.l10n.profileNotSet,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: header.bio?.isNotEmpty == true
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountInfoCard extends ConsumerWidget {
  const _AccountInfoCard();

  static String _formatDate(DateTime date) {
    return DateFormat.yMMMd(Intl.getCurrentLocale()).format(date);
  }

  Future<void> _editTimezone(
    BuildContext context,
    WidgetRef ref, {
    required String timezone,
  }) async {
    await showProfileSettingsEditor<void>(
      context: context,
      builder: (_) => ProfileTimezoneEditor(
        initialTimezone: timezone,
        onSubmitted: (value) =>
            _saveProfileUpdates(context, ref, updates: {'timezone': value}),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountInfo = ref.watch(
      profileUserProvider.select(
        (user) => (
          createdAt: user?.createdAt,
          email: user?.email,
          timezone: user?.timezone ?? '',
        ),
      ),
    );
    final memberSince = accountInfo.createdAt != null
        ? _formatDate(accountInfo.createdAt!)
        : context.l10n.profileUnknown;

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
            value: accountInfo.email ?? context.l10n.profileNotSet,
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
                    _ChangeEmailDialog(initialEmail: accountInfo.email?.trim()),
              );
              if (result == null || !context.mounted) return;

              try {
                await ref.read(profileNotifierProvider.notifier).updateProfile({
                  'email': result,
                });
              } catch (error) {
                if (!context.mounted) return;
                AppToast.error(
                  context,
                  context.l10n.profileChangeEmailFailed(
                    ApiError.userMessage(error, context.l10n),
                  ),
                );
                return;
              }

              if (!context.mounted) return;
              ref.invalidate(authNotifierProvider);
              AppToast.success(context, context.l10n.profileChangeEmailSuccess);
              await ref.read(appHapticsProvider).success();
            },
          ),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.public,
            label: context.l10n.profileTimezoneLabel,
            value: accountInfo.timezone.replaceAll('_', ' '),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 18,
            ),
            onTap: () =>
                _editTimezone(context, ref, timezone: accountInfo.timezone),
          ),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: context.l10n.profileMemberSinceLabel,
            value: memberSince,
          ),
        ],
      ),
    );
  }
}

class _ProfileActions extends ConsumerWidget {
  const _ProfileActions();

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

class _GamingHoursCard extends ConsumerWidget {
  const _GamingHoursCard();

  Future<void> _editGamingHours(
    BuildContext context,
    WidgetRef ref, {
    required Map<String, dynamic>? gamingHours,
  }) async {
    await showProfileSettingsEditor<void>(
      context: context,
      builder: (_) => ProfileGamingHoursEditor(
        initialHours: gamingHours,
        onSubmitted: (value) => _saveProfileUpdates(
          context,
          ref,
          updates: {'preferred_gaming_hours': value},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamingHours = ref.watch(
      profileUserProvider.select((user) => user?.preferredGamingHours),
    );

    return GlassCard(
      onTap: () => _editGamingHours(context, ref, gamingHours: gamingHours),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: context.l10n.profileSectionGamingHours),
          const SizedBox(height: AppSpacing.md),
          GamingHoursDisplay(gamingHours: gamingHours),
        ],
      ),
    );
  }
}

class _ConnectedAccountsCard extends ConsumerWidget {
  const _ConnectedAccountsCard();

  int _authMethodCount({
    required bool hasPasswordLogin,
    required String? steamId,
    required String? appleId,
    required List<ProviderIdentity> providerIdentities,
  }) {
    var count = 0;
    if (hasPasswordLogin) count++;
    for (final identity in providerIdentities) {
      if (identity.supportsLogin) count++;
    }
    if (steamId != null &&
        _identityFor(
              'steam',
              steamId: steamId,
              appleId: appleId,
              providerIdentities: providerIdentities,
            )?.externalId ==
            null) {
      count++;
    }
    if (appleId != null &&
        _identityFor(
              'apple',
              steamId: steamId,
              appleId: appleId,
              providerIdentities: providerIdentities,
            )?.externalId ==
            null) {
      count++;
    }
    return count;
  }

  ProviderIdentity? _identityFor(
    String provider, {
    required String? steamId,
    required String? appleId,
    required List<ProviderIdentity> providerIdentities,
  }) {
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
    return currentAppLocalizations().profileConnected;
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

  Future<void> _handleSteamTap(
    BuildContext context,
    WidgetRef ref, {
    required String? steamId,
    required String? appleId,
    required List<ProviderIdentity> providerIdentities,
    required bool hasPasswordLogin,
  }) async {
    final steamIdentity = _identityFor(
      'steam',
      steamId: steamId,
      appleId: appleId,
      providerIdentities: providerIdentities,
    );
    if (steamIdentity != null) {
      if (_authMethodCount(
            hasPasswordLogin: hasPasswordLogin,
            steamId: steamId,
            appleId: appleId,
            providerIdentities: providerIdentities,
          ) <=
          1) {
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
        await ref.read(profileNotifierProvider.notifier).unlinkSteam();
        ref.invalidate(authNotifierProvider);
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
        await ref.read(profileNotifierProvider.notifier).linkSteam(params);
        ref.invalidate(authNotifierProvider);
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

  Future<void> _handleEmailTap(
    BuildContext context,
    WidgetRef ref, {
    required String? email,
    required bool hasPasswordLogin,
  }) async {
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
          .read(profileNotifierProvider.notifier)
          .setEmailPassword(email: result.email, password: result.password);
      ref.invalidate(authNotifierProvider);
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

  Future<void> _handleDiscordTap(
    BuildContext context,
    WidgetRef ref, {
    required String? steamId,
    required String? appleId,
    required List<ProviderIdentity> providerIdentities,
    required bool hasPasswordLogin,
  }) async {
    final discordIdentity = _identityFor(
      'discord',
      steamId: steamId,
      appleId: appleId,
      providerIdentities: providerIdentities,
    );
    if (discordIdentity != null) {
      if (_authMethodCount(
            hasPasswordLogin: hasPasswordLogin,
            steamId: steamId,
            appleId: appleId,
            providerIdentities: providerIdentities,
          ) <=
          1) {
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
        await ref.read(profileNotifierProvider.notifier).unlinkDiscord();
        ref.invalidate(authNotifierProvider);
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
            .read(profileNotifierProvider.notifier)
            .linkDiscord(
              code: discordAuthResult.code,
              codeVerifier: discordAuthResult.codeVerifier,
              redirectUri: discordAuthResult.redirectUri,
            );
        ref.invalidate(authNotifierProvider);
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

  Future<void> _handleAppleTap(
    BuildContext context,
    WidgetRef ref, {
    required String? steamId,
    required String? appleId,
    required List<ProviderIdentity> providerIdentities,
    required bool hasPasswordLogin,
  }) async {
    final appleIdentity = _identityFor(
      'apple',
      steamId: steamId,
      appleId: appleId,
      providerIdentities: providerIdentities,
    );
    if (appleIdentity != null) {
      if (_authMethodCount(
            hasPasswordLogin: hasPasswordLogin,
            steamId: steamId,
            appleId: appleId,
            providerIdentities: providerIdentities,
          ) <=
          1) {
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
        await ref.read(profileNotifierProvider.notifier).unlinkApple();
        ref.invalidate(authNotifierProvider);
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
            .read(profileNotifierProvider.notifier)
            .linkApple(appleSignInResult.identityToken);
        ref.invalidate(authNotifierProvider);
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
    final connectedAccounts = ref.watch(
      profileUserProvider.select(
        (user) => (
          appleId: user?.appleId,
          email: user?.email,
          hasPasswordLogin: user?.hasPasswordLogin ?? false,
          providerIdentities:
              user?.providerIdentities ?? const <ProviderIdentity>[],
          steamId: user?.steamId,
        ),
      ),
    );
    final steamIdentity = _identityFor(
      'steam',
      steamId: connectedAccounts.steamId,
      appleId: connectedAccounts.appleId,
      providerIdentities: connectedAccounts.providerIdentities,
    );
    final discordIdentity = _identityFor(
      'discord',
      steamId: connectedAccounts.steamId,
      appleId: connectedAccounts.appleId,
      providerIdentities: connectedAccounts.providerIdentities,
    );
    final appleIdentity = _identityFor(
      'apple',
      steamId: connectedAccounts.steamId,
      appleId: connectedAccounts.appleId,
      providerIdentities: connectedAccounts.providerIdentities,
    );
    final authMethodCount = _authMethodCount(
      hasPasswordLogin: connectedAccounts.hasPasswordLogin,
      steamId: connectedAccounts.steamId,
      appleId: connectedAccounts.appleId,
      providerIdentities: connectedAccounts.providerIdentities,
    );
    final steamConnected = steamIdentity != null;
    final discordConnected = discordIdentity != null;
    final appleConnected = appleIdentity != null;
    final canDisconnectSteam = steamConnected && authMethodCount > 1;
    final canDisconnectDiscord = discordConnected && authMethodCount > 1;
    final canDisconnectApple = appleConnected && authMethodCount > 1;
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
            connected: connectedAccounts.hasPasswordLogin,
            iconColor: ProviderVisuals.rowIconColor(
              'email',
              connected: connectedAccounts.hasPasswordLogin,
            ),
            iconBackgroundColor: ProviderVisuals.rowIconBackground(
              'email',
              connected: connectedAccounts.hasPasswordLogin,
            ),
            onTap: connectedAccounts.hasPasswordLogin
                ? null
                : () => _handleEmailTap(
                    context,
                    ref,
                    email: connectedAccounts.email,
                    hasPasswordLogin: connectedAccounts.hasPasswordLogin,
                  ),
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
            onTap: steamConnected
                ? (canDisconnectSteam
                      ? () => _handleSteamTap(
                          context,
                          ref,
                          steamId: connectedAccounts.steamId,
                          appleId: connectedAccounts.appleId,
                          providerIdentities:
                              connectedAccounts.providerIdentities,
                          hasPasswordLogin: connectedAccounts.hasPasswordLogin,
                        )
                      : null)
                : () => _handleSteamTap(
                    context,
                    ref,
                    steamId: connectedAccounts.steamId,
                    appleId: connectedAccounts.appleId,
                    providerIdentities: connectedAccounts.providerIdentities,
                    hasPasswordLogin: connectedAccounts.hasPasswordLogin,
                  ),
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
              onTap: discordConnected
                  ? (canDisconnectDiscord
                        ? () => _handleDiscordTap(
                            context,
                            ref,
                            steamId: connectedAccounts.steamId,
                            appleId: connectedAccounts.appleId,
                            providerIdentities:
                                connectedAccounts.providerIdentities,
                            hasPasswordLogin:
                                connectedAccounts.hasPasswordLogin,
                          )
                        : null)
                  : () => _handleDiscordTap(
                      context,
                      ref,
                      steamId: connectedAccounts.steamId,
                      appleId: connectedAccounts.appleId,
                      providerIdentities: connectedAccounts.providerIdentities,
                      hasPasswordLogin: connectedAccounts.hasPasswordLogin,
                    ),
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
              onTap: appleConnected
                  ? (canDisconnectApple
                        ? () => _handleAppleTap(
                            context,
                            ref,
                            steamId: connectedAccounts.steamId,
                            appleId: connectedAccounts.appleId,
                            providerIdentities:
                                connectedAccounts.providerIdentities,
                            hasPasswordLogin:
                                connectedAccounts.hasPasswordLogin,
                          )
                        : null)
                  : () => _handleAppleTap(
                      context,
                      ref,
                      steamId: connectedAccounts.steamId,
                      appleId: connectedAccounts.appleId,
                      providerIdentities: connectedAccounts.providerIdentities,
                      hasPasswordLogin: connectedAccounts.hasPasswordLogin,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialIdentitiesCard extends ConsumerWidget {
  const _SocialIdentitiesCard();

  String? _generatedXboxProfileUrl(ProviderIdentity? identity) {
    final gamertag = identity?.username?.trim() ?? identity?.externalId?.trim();
    if (gamertag == null || gamertag.isEmpty) return null;
    return 'https://account.xbox.com/en-us/profile?gamertag=${Uri.encodeComponent(gamertag)}';
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
          socialProviderLabel(context, provider),
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
            socialProviderLabel(context, provider),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        context.l10n.profileSocialIdentityOpenFailed(
          socialProviderLabel(context, provider),
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
          socialProviderLabel(context, provider),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        context.l10n.profileSocialIdentityCopyFailed(
          socialProviderLabel(context, provider),
        ),
      );
    }
  }

  Future<void> _linkSteam(BuildContext context, WidgetRef ref) async {
    try {
      final params = await OAuthLauncher.launchSteamAuth();
      if (!context.mounted) return;
      await ref.read(profileNotifierProvider.notifier).linkSteam(params);
      ref.invalidate(authNotifierProvider);
      if (context.mounted) {
        AppToast.success(context, context.l10n.profileSteamLinkedSuccess);
      }
      await ref.read(appHapticsProvider).success();
    } catch (error) {
      if (!context.mounted) return;
      final message = OAuthLauncher.toFailure(error).userMessage(context.l10n);
      if (!OAuthLauncher.isCancellationError(error)) {
        AppToast.error(context, context.l10n.profileLinkSteamFailed(message));
      }
    }
  }

  Future<void> _linkDiscord(BuildContext context, WidgetRef ref) async {
    final DiscordAuthResult? discordAuthResult;
    try {
      discordAuthResult = await OAuthLauncher.launchDiscordAuth();
    } catch (error) {
      if (!context.mounted || OAuthLauncher.isCancellationError(error)) return;
      AppToast.error(
        context,
        OAuthLauncher.toFailure(error).userMessage(context.l10n),
      );
      return;
    }

    if (!context.mounted) return;

    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .linkDiscord(
            code: discordAuthResult.code,
            codeVerifier: discordAuthResult.codeVerifier,
            redirectUri: discordAuthResult.redirectUri,
          );
      ref.invalidate(authNotifierProvider);
      if (context.mounted) {
        AppToast.success(context, context.l10n.profileDiscordLinkedSuccess);
      }
      await ref.read(appHapticsProvider).success();
    } catch (error) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        context.l10n.profileLinkDiscordFailed(
          ApiError.userMessage(error, context.l10n),
        ),
      );
    }
  }

  Future<void> _handleManualSocialTap(
    BuildContext context,
    WidgetRef ref, {
    required String provider,
    required String? steamId,
    required List<ProviderIdentity> providerIdentities,
  }) async {
    final identity = socialIdentityFor(
      provider,
      steamId: steamId,
      providerIdentities: providerIdentities,
    );
    if (identity == null) {
      await _handleManualIdentityTap(
        context,
        ref,
        provider: provider,
        steamId: steamId,
        providerIdentities: providerIdentities,
      );
      return;
    }

    switch (provider) {
      case 'xbox':
        final profileUrl =
            socialProfileUrl(identity) ?? _generatedXboxProfileUrl(identity);
        if (profileUrl == null) {
          if (!context.mounted) return;
          AppToast.error(
            context,
            context.l10n.profileSocialIdentityOpenFailed(
              socialProviderLabel(context, provider),
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
        final profileUrl = socialProfileUrl(identity);
        if (profileUrl == null) {
          if (!context.mounted) return;
          AppToast.error(
            context,
            context.l10n.profileSocialIdentityOpenFailed(
              socialProviderLabel(context, provider),
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
        final friendCode = nintendoFriendCode(identity);
        if (friendCode == null) {
          if (!context.mounted) return;
          AppToast.error(
            context,
            context.l10n.profileSocialIdentityCopyFailed(
              socialProviderLabel(context, provider),
            ),
          );
          return;
        }
        await _copySocialValue(context, provider: provider, value: friendCode);
        return;
      default:
        await _handleManualIdentityTap(
          context,
          ref,
          provider: provider,
          steamId: steamId,
          providerIdentities: providerIdentities,
        );
        return;
    }
  }

  Widget? _manualSocialTrailing(
    BuildContext context, {
    required String provider,
    required ProviderIdentity? identity,
    required VoidCallback onEdit,
    required VoidCallback onRemove,
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
        AppPopupMenuButton<_SocialRowAction>(
          tooltip: context.l10n.commonEdit,
          icon: const Icon(
            Icons.more_horiz,
            color: AppColors.textTertiary,
            size: 18,
          ),
          padding: const EdgeInsets.all(6),
          itemBuilder: (_) => [
            PopupMenuItem<_SocialRowAction>(
              value: _SocialRowAction.edit,
              child: Text(context.l10n.commonEdit),
            ),
            PopupMenuItem<_SocialRowAction>(
              value: _SocialRowAction.remove,
              child: Text(
                context.l10n.commonRemove,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
          onSelected: (action) {
            switch (action) {
              case _SocialRowAction.edit:
                onEdit();
                break;
              case _SocialRowAction.remove:
                onRemove();
                break;
            }
          },
        ),
      ],
    );
  }

  Future<void> _removeManualIdentity(
    BuildContext context,
    WidgetRef ref, {
    required String provider,
  }) async {
    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .deleteManualSocialIdentity(provider);
      if (context.mounted) {
        AppToast.success(
          context,
          context.l10n.profileSocialIdentityRemovedSuccess(
            socialProviderLabel(context, provider),
          ),
        );
      }
      await ref.read(appHapticsProvider).destructiveConfirm();
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        context.l10n.profileSocialIdentitySaveFailed(
          socialProviderLabel(context, provider),
          ApiError.userMessage(e, context.l10n),
        ),
      );
    }
  }

  Future<void> _handleManualIdentityTap(
    BuildContext context,
    WidgetRef ref, {
    required String provider,
    required String? steamId,
    required List<ProviderIdentity> providerIdentities,
  }) async {
    final existing = socialIdentityFor(
      provider,
      steamId: steamId,
      providerIdentities: providerIdentities,
    );
    final result = await showDialog<_ManualSocialIdentityDialogResult>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _ManualSocialIdentityDialog(
        provider: provider,
        label: socialProviderLabel(context, provider),
        existing: existing,
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      if (result.remove) {
        await ref
            .read(profileNotifierProvider.notifier)
            .deleteManualSocialIdentity(provider);
        if (context.mounted) {
          AppToast.success(
            context,
            context.l10n.profileSocialIdentityRemovedSuccess(
              socialProviderLabel(context, provider),
            ),
          );
        }
        await ref.read(appHapticsProvider).destructiveConfirm();
        return;
      }

      await ref
          .read(profileNotifierProvider.notifier)
          .upsertManualSocialIdentity(
            provider: provider,
            externalId: result.externalId,
            username: result.username,
            displayName: result.displayName,
            profileUrl: result.profileUrl,
          );
      if (context.mounted) {
        AppToast.success(
          context,
          context.l10n.profileSocialIdentitySavedSuccess(
            socialProviderLabel(context, provider),
          ),
        );
      }
      await ref.read(appHapticsProvider).success();
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        context.l10n.profileSocialIdentitySaveFailed(
          socialProviderLabel(context, provider),
          ApiError.userMessage(e, context.l10n),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialIdentities = ref.watch(
      profileUserProvider.select(
        (user) => (
          providerIdentities:
              user?.providerIdentities ?? const <ProviderIdentity>[],
          steamId: user?.steamId,
        ),
      ),
    );
    final steamIdentity = socialIdentityFor(
      'steam',
      steamId: socialIdentities.steamId,
      providerIdentities: socialIdentities.providerIdentities,
    );
    final discordIdentity = socialIdentityFor(
      'discord',
      steamId: socialIdentities.steamId,
      providerIdentities: socialIdentities.providerIdentities,
    );
    final xboxIdentity = socialIdentityFor(
      'xbox',
      steamId: socialIdentities.steamId,
      providerIdentities: socialIdentities.providerIdentities,
    );
    final playStationIdentity = socialIdentityFor(
      'playstation',
      steamId: socialIdentities.steamId,
      providerIdentities: socialIdentities.providerIdentities,
    );
    final nintendoIdentity = socialIdentityFor(
      'nintendo',
      steamId: socialIdentities.steamId,
      providerIdentities: socialIdentities.providerIdentities,
    );
    final steamProfileUrl = socialProfileUrl(steamIdentity);
    final discordProfileUrl = socialProfileUrl(discordIdentity);
    final showDiscordRow =
        discordIdentity != null || OAuthLauncher.discordSignInAvailable;
    final entries = <SocialIdentityCardEntry>[
      SocialIdentityCardEntry(
        provider: 'steam',
        label: context.l10n.profileConnectedAccountsSteam,
        connected: steamIdentity != null,
        subtitle: socialIdentityStatus(
          context,
          provider: 'steam',
          identity: steamIdentity,
        ),
        onTap: steamIdentity == null
            ? () => _linkSteam(context, ref)
            : (steamProfileUrl == null
                  ? null
                  : () => _openSocialProfile(
                      context,
                      provider: 'steam',
                      profileUrl: steamProfileUrl,
                    )),
      ),
      if (showDiscordRow)
        SocialIdentityCardEntry(
          provider: 'discord',
          label: context.l10n.profileConnectedAccountsDiscord,
          connected: discordIdentity != null,
          subtitle: socialIdentityStatus(
            context,
            provider: 'discord',
            identity: discordIdentity,
          ),
          onTap: discordIdentity == null
              ? () => _linkDiscord(context, ref)
              : (discordProfileUrl == null
                    ? null
                    : () => _openSocialProfile(
                        context,
                        provider: 'discord',
                        profileUrl: discordProfileUrl,
                      )),
        ),
      SocialIdentityCardEntry(
        provider: 'xbox',
        label: context.l10n.profileConnectedAccountsXbox,
        connected: xboxIdentity != null,
        subtitle: socialIdentityStatus(
          context,
          provider: 'xbox',
          identity: xboxIdentity,
        ),
        trailing: _manualSocialTrailing(
          context,
          provider: 'xbox',
          identity: xboxIdentity,
          onEdit: () {
            _handleManualIdentityTap(
              context,
              ref,
              provider: 'xbox',
              steamId: socialIdentities.steamId,
              providerIdentities: socialIdentities.providerIdentities,
            );
          },
          onRemove: () {
            _removeManualIdentity(context, ref, provider: 'xbox');
          },
        ),
        onTap: () => _handleManualSocialTap(
          context,
          ref,
          provider: 'xbox',
          steamId: socialIdentities.steamId,
          providerIdentities: socialIdentities.providerIdentities,
        ),
      ),
      SocialIdentityCardEntry(
        provider: 'playstation',
        label: context.l10n.profileConnectedAccountsPlayStation,
        connected: playStationIdentity != null,
        subtitle: socialIdentityStatus(
          context,
          provider: 'playstation',
          identity: playStationIdentity,
        ),
        trailing: _manualSocialTrailing(
          context,
          provider: 'playstation',
          identity: playStationIdentity,
          onEdit: () {
            _handleManualIdentityTap(
              context,
              ref,
              provider: 'playstation',
              steamId: socialIdentities.steamId,
              providerIdentities: socialIdentities.providerIdentities,
            );
          },
          onRemove: () {
            _removeManualIdentity(context, ref, provider: 'playstation');
          },
        ),
        onTap: () => _handleManualSocialTap(
          context,
          ref,
          provider: 'playstation',
          steamId: socialIdentities.steamId,
          providerIdentities: socialIdentities.providerIdentities,
        ),
      ),
      SocialIdentityCardEntry(
        provider: 'nintendo',
        label: context.l10n.profileConnectedAccountsNintendo,
        connected: nintendoIdentity != null,
        subtitle: socialIdentityStatus(
          context,
          provider: 'nintendo',
          identity: nintendoIdentity,
        ),
        trailing: _manualSocialTrailing(
          context,
          provider: 'nintendo',
          identity: nintendoIdentity,
          onEdit: () {
            _handleManualIdentityTap(
              context,
              ref,
              provider: 'nintendo',
              steamId: socialIdentities.steamId,
              providerIdentities: socialIdentities.providerIdentities,
            );
          },
          onRemove: () {
            _removeManualIdentity(context, ref, provider: 'nintendo');
          },
        ),
        onTap: () => _handleManualSocialTap(
          context,
          ref,
          provider: 'nintendo',
          steamId: socialIdentities.steamId,
          providerIdentities: socialIdentities.providerIdentities,
        ),
      ),
    ];

    return SocialIdentitiesCard(
      title: context.l10n.profileSectionSocials,
      entries: entries,
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool connected;
  final String? statusText;
  final Color? iconColor;
  final Color? iconBackgroundColor;
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
