import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../providers/profile_provider.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/gaming_hours_editor.dart';
import '../widgets/timezone_selector.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late String _timezone;
  Map<String, dynamic>? _gamingHours;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileNotifierProvider).valueOrNull;
    _displayNameController =
        TextEditingController(text: user?.displayName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _timezone = user?.timezone ?? 'America/New_York';
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updates = <String, dynamic>{
      'display_name': _displayNameController.text.trim(),
      'bio': _bioController.text.trim(),
      'timezone': _timezone,
      if (_gamingHours != null) 'preferred_gaming_hours': _gamingHours,
    };

    await ref.read(profileNotifierProvider.notifier).updateProfile(updates);

    if (mounted) {
      setState(() => _isSaving = false);
      final state = ref.read(profileNotifierProvider);
      if (state.hasError) {
        AppToast.error(context, state.error.toString());
      } else {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileNotifierProvider).valueOrNull;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Edit Profile',
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
                    child: AvatarPicker(
                      imageUrl: user?.avatarUrl,
                      displayName: user?.displayName ?? '',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  GlassInput(
                    controller: _displayNameController,
                    label: 'Display Name',
                    hint: 'Enter your display name',
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
                    controller: _bioController,
                    label: 'Bio',
                    hint: 'Tell others about yourself',
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
                      onPressed: _isSaving ? null : _save,
                      isLoading: _isSaving,
                      child: const Text('Save Changes'),
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
