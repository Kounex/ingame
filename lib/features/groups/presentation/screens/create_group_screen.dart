import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_aware_form_state_mixin.dart';
import '../../../../core/networking/api_error.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/app_switch_row.dart';
import '../../../../shared/widgets/desktop_content_region.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/services/app_haptics.dart';
import '../providers/groups_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen>
    with LocaleAwareFormStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isDiscoverable = false;
  String _joinMode = 'open';
  bool _isLoading = false;
  bool _hasAttemptedSubmit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _hasAttemptedSubmit = true;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final group = await ref
          .read(groupsNotifierProvider.notifier)
          .create(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            isDiscoverable: _isDiscoverable,
            joinMode: _joinMode,
          );
      if (mounted) {
        await ref.read(appHapticsProvider).success();
        context.pushReplacementNamed(
          RouteNames.groupDetail,
          pathParameters: {'id': group.id},
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ApiError.userMessage(e, context.l10n));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    revalidateFormOnLocaleChange(
      formKey: _formKey,
      shouldRevalidate: _hasAttemptedSubmit,
    );

    return AppBackgroundSurface(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: l10n.createGroupTitle,
          contentWidth: DesktopContentWidth.form,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: DesktopContentRegion(
          width: DesktopContentWidth.form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  GlassInput(
                    controller: _nameController,
                    label: l10n.createGroupNameLabel,
                    hint: l10n.createGroupNameHint,
                    prefixIcon: Icons.groups,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.createGroupNameRequired;
                      }
                      if (value.trim().length < 3) {
                        return l10n.createGroupNameMin;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassInput(
                    controller: _descriptionController,
                    label: l10n.createGroupDescriptionLabel,
                    hint: l10n.createGroupDescriptionHint,
                    prefixIcon: Icons.description_outlined,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSwitchRow(
                          title: l10n.createGroupDiscoverableTitle,
                          subtitle: l10n.createGroupDiscoverableSubtitle,
                          value: _isDiscoverable,
                          onChanged: (v) {
                            setState(() => _isDiscoverable = v);
                            ref.read(appHapticsProvider).selection();
                          },
                        ),
                        if (_isDiscoverable) ...[
                          const Divider(height: 24),
                          Text(
                            l10n.createGroupJoinModeLabel,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'open',
                                label: Text(l10n.groupJoinModeOpenLabel),
                                icon: const Icon(Icons.open_in_new, size: 16),
                              ),
                              ButtonSegment(
                                value: 'approval',
                                label: Text(l10n.groupJoinModeApprovalLabel),
                                icon: const Icon(Icons.approval, size: 16),
                              ),
                            ],
                            selected: {_joinMode},
                            onSelectionChanged: (v) {
                              setState(() => _joinMode = v.first);
                              ref.read(appHapticsProvider).selection();
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppColors.primary.withValues(
                                    alpha: 0.2,
                                  );
                                }
                                return AppColors.glassSurface;
                              }),
                              foregroundColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppColors.primary;
                                }
                                return AppColors.textSecondary;
                              }),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _joinMode == 'open'
                                ? l10n.groupJoinModeOpenDescription
                                : l10n.groupJoinModeApprovalDescription,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  GlassButton(
                    onPressed: _submit,
                    isLoading: _isLoading,
                    child: Text(l10n.createGroupSubmit),
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
