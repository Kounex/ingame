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
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/editable_avatar_field.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
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
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileNotifierProvider).value;
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
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: context.l10n.editProfileTitle,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
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
                    onChanged: (value) => setState(() => _timezone = value),
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
    );
  }
}
