import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_aware_form_state_mixin.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/extensions.dart';
import 'gaming_hours_editor.dart';
import 'timezone_selector.dart';

typedef ProfileValueSubmit<T> = FutureOr<bool> Function(T value);

Future<T?> showProfileSettingsEditor<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  if (context.isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
          ),
          child: builder(sheetContext),
        ),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    builder: builder,
  );
}

class ProfileTextValueEditor extends StatefulWidget {
  const ProfileTextValueEditor({
    super.key,
    required this.title,
    required this.label,
    required this.initialValue,
    required this.onSubmitted,
    this.validator,
    this.hint,
    this.maxLines = 1,
  });

  final String title;
  final String label;
  final String initialValue;
  final String? Function(String?)? validator;
  final String? hint;
  final int maxLines;
  final ProfileValueSubmit<String> onSubmitted;

  @override
  State<ProfileTextValueEditor> createState() => _ProfileTextValueEditorState();
}

class _ProfileTextValueEditorState extends State<ProfileTextValueEditor>
    with LocaleAwareFormStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _hasAttemptedSubmit = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _hasAttemptedSubmit = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final shouldClose = await widget.onSubmitted(_controller.text.trim());
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (shouldClose) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    revalidateFormOnLocaleChange(
      formKey: _formKey,
      shouldRevalidate: _hasAttemptedSubmit,
    );

    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GlassInput(
            controller: _controller,
            label: widget.label,
            hint: widget.hint,
            validator: widget.validator,
            maxLines: widget.maxLines,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  variant: GlassButtonVariant.secondary,
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(context.l10n.commonCancel),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GlassButton(
                  onPressed: _isSaving ? null : _submit,
                  isLoading: _isSaving,
                  child: Text(context.l10n.commonSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return _ProfileSettingsEditorContainer(child: content);
  }
}

class ProfileTimezoneEditor extends StatefulWidget {
  const ProfileTimezoneEditor({
    super.key,
    required this.initialTimezone,
    required this.onSubmitted,
  });

  final String initialTimezone;
  final ProfileValueSubmit<String> onSubmitted;

  @override
  State<ProfileTimezoneEditor> createState() => _ProfileTimezoneEditorState();
}

class _ProfileTimezoneEditorState extends State<ProfileTimezoneEditor> {
  late String _timezone;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _timezone = widget.initialTimezone;
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final shouldClose = await widget.onSubmitted(_timezone);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (shouldClose) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileSettingsEditorContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.profileEditTimezoneTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TimezoneSelector(
            selectedTimezone: _timezone,
            onChanged: (value) => setState(() => _timezone = value),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  variant: GlassButtonVariant.secondary,
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(context.l10n.commonCancel),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GlassButton(
                  onPressed: _isSaving ? null : _submit,
                  isLoading: _isSaving,
                  child: Text(context.l10n.commonSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileGamingHoursEditor extends StatefulWidget {
  const ProfileGamingHoursEditor({
    super.key,
    required this.initialHours,
    required this.onSubmitted,
  });

  final Map<String, dynamic>? initialHours;
  final ProfileValueSubmit<Map<String, dynamic>> onSubmitted;

  @override
  State<ProfileGamingHoursEditor> createState() =>
      _ProfileGamingHoursEditorState();
}

class _ProfileGamingHoursEditorState extends State<ProfileGamingHoursEditor> {
  Map<String, dynamic>? _hours;
  bool _isSaving = false;

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final shouldClose = await widget.onSubmitted(
      _hours ?? widget.initialHours ?? <String, dynamic>{},
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (shouldClose) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileSettingsEditorContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.profileEditGamingHoursTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: GamingHoursEditor(
                initialHours: widget.initialHours,
                onChanged: (value) => _hours = value,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  variant: GlassButtonVariant.secondary,
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(context.l10n.commonCancel),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GlassButton(
                  onPressed: _isSaving ? null : _submit,
                  isLoading: _isSaving,
                  child: Text(context.l10n.commonSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSettingsEditorContainer extends StatelessWidget {
  const _ProfileSettingsEditorContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = GlassCard(child: child);

    if (context.isMobile) {
      return surface;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: surface,
      ),
    );
  }
}
