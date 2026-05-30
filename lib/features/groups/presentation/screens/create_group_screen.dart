import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../providers/groups_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isDiscoverable = false;
  String _joinMode = 'open';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final group = await ref.read(groupsNotifierProvider.notifier).create(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            isDiscoverable: _isDiscoverable,
            joinMode: _joinMode,
          );
      if (mounted) {
        context.pushReplacementNamed(
          RouteNames.groupDetail,
          pathParameters: {'id': group.id},
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: GlassAppBar(
          title: 'Create Group',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                GlassInput(
                  controller: _nameController,
                  label: 'Group Name',
                  hint: 'Enter a name for your group',
                  prefixIcon: Icons.groups,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Group name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                GlassInput(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'What is this group about? (optional)',
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Discoverable',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Allow others to find and join this group',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isDiscoverable,
                            onChanged: (v) =>
                                setState(() => _isDiscoverable = v),
                            activeTrackColor: AppColors.primary,
                          ),
                        ],
                      ),
                      if (_isDiscoverable) ...[
                        const Divider(color: AppColors.glassBorder, height: 24),
                        const Text(
                          'Join Mode',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'open',
                              label: Text('Open'),
                              icon: Icon(Icons.open_in_new, size: 16),
                            ),
                            ButtonSegment(
                              value: 'approval',
                              label: Text('Approval'),
                              icon: Icon(Icons.approval, size: 16),
                            ),
                          ],
                          selected: {_joinMode},
                          onSelectionChanged: (v) =>
                              setState(() => _joinMode = v.first),
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppColors.primary.withValues(alpha: 0.2);
                              }
                              return AppColors.glassSurface;
                            }),
                            foregroundColor:
                                WidgetStateProperty.resolveWith((states) {
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
                              ? 'Anyone can join instantly'
                              : 'Members must be approved by an admin',
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
                  child: const Text('Create Group'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
