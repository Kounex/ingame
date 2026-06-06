import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_aware_form_state_mixin.dart';
import '../../../../core/networking/api_error.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../../../shared/widgets/editable_avatar_field.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/services/app_haptics.dart';
import '../providers/profile_provider.dart';
import '../widgets/gaming_hours_editor.dart';
import '../widgets/timezone_selector.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with LocaleAwareFormStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late String _timezone;
  String? _avatarUrl;
  String? _initialAvatarUrl;
  bool _avatarChanged = false;
  Map<String, dynamic>? _gamingHours;
  bool _isSaving = false;
  bool _hasAttemptedSave = false;
  bool _didHydrateProfile = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileNotifierProvider).value;
    _displayNameController = TextEditingController(
      text: user?.displayName ?? '',
    );
    _bioController = TextEditingController(text: user?.bio ?? '');
    _timezone = user?.timezone ?? 'America/New_York';
    _avatarUrl = user?.avatarUrl;
    _initialAvatarUrl = user?.avatarUrl;
    _gamingHours = user?.preferredGamingHours != null
        ? Map<String, dynamic>.from(user!.preferredGamingHours!)
        : null;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _hasAttemptedSave = true;
    if (!_didHydrateProfile) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updates = <String, dynamic>{
      'display_name': _displayNameController.text.trim(),
      'bio': _bioController.text.trim(),
      'timezone': _timezone,
      if (_avatarChanged) 'avatar_url': _avatarUrl,
      if (_gamingHours != null) 'preferred_gaming_hours': _gamingHours,
    };

    await ref.read(profileNotifierProvider.notifier).updateProfile(updates);

    if (mounted) {
      setState(() => _isSaving = false);
      final state = ref.read(profileNotifierProvider);
      if (state.hasError) {
        AppToast.error(
          context,
          ApiError.userMessage(state.error!, context.l10n),
        );
      } else {
        await ref.read(appHapticsProvider).success();
        if (!mounted) return;
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final user = profileState.value;

    if (user != null && !_didHydrateProfile) {
      _displayNameController.text = user.displayName;
      _bioController.text = user.bio ?? '';
      _timezone = user.timezone;
      _avatarUrl = user.avatarUrl;
      _initialAvatarUrl = user.avatarUrl;
      _gamingHours = user.preferredGamingHours != null
          ? Map<String, dynamic>.from(user.preferredGamingHours!)
          : null;
      _didHydrateProfile = true;
    }

    final showLoadingState = !_didHydrateProfile && profileState.isLoading;
    final showMissingProfileState =
        !_didHydrateProfile && !profileState.isLoading;
    final avatarDisplayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : (_displayNameController.text.trim().isNotEmpty
              ? _displayNameController.text.trim()
              : context.l10n.profileUnknown);

    revalidateFormOnLocaleChange(
      formKey: _formKey,
      shouldRevalidate: _hasAttemptedSave,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: context.l10n.editProfileTitle,
        contentWidth: DesktopContentWidth.form,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: AppBackgroundSurface(
        child: SafeArea(
          child: DesktopContentRegion(
            width: DesktopContentWidth.form,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: showLoadingState
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(
                        child: SizedBox(
                          key: Key('edit-profile-loading-indicator'),
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  : showMissingProfileState
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl,
                      ),
                      child: Column(
                        children: [
                          Text(
                            context.l10n.errorSomethingWentWrong,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          GlassButton(
                            onPressed: () => ref
                                .read(profileNotifierProvider.notifier)
                                .load(),
                            child: Text(context.l10n.commonRetry),
                          ),
                        ],
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          Center(
                            child: EditableAvatarField(
                              initialAvatarUrl: _avatarUrl,
                              displayName: avatarDisplayName,
                              onChanged: (value) {
                                setState(() {
                                  _avatarUrl = value;
                                  _avatarChanged = value != _initialAvatarUrl;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          GlassInput(
                            controller: _displayNameController,
                            label: context.l10n.registerDisplayNameLabel,
                            hint: context.l10n.editProfileDisplayNameHint,
                            prefixIcon: Icons.person_outline,
                            validator: FormValidators.displayName,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          GlassInput(
                            controller: _bioController,
                            label: context.l10n.editProfileBioLabel,
                            hint: context.l10n.editProfileBioHint,
                            prefixIcon: Icons.info_outline,
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          TimezoneSelector(
                            selectedTimezone: _timezone,
                            onChanged: (value) =>
                                setState(() => _timezone = value),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          GamingHoursEditor(
                            initialHours: _gamingHours,
                            onChanged: (hours) => _gamingHours = hours,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            child: GlassButton(
                              key: const Key('edit-profile-save-button'),
                              onPressed: _isSaving ? null : _save,
                              isLoading: _isSaving,
                              child: Text(context.l10n.editProfileSave),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
