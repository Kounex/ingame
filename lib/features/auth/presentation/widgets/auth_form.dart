import 'package:flutter/material.dart';

import '../../../../core/theme/glass_components.dart';
import '../../../../core/theme/spacing.dart';

class AuthForm extends StatelessWidget {
  const AuthForm({
    super.key,
    required this.formKey,
    required this.children,
    required this.onSubmit,
    required this.submitLabel,
    this.isLoading = false,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final VoidCallback onSubmit;
  final String submitLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          const SizedBox(height: AppSpacing.lg),
          GlassButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                onSubmit();
              }
            },
            variant: GlassButtonVariant.primary,
            isLoading: isLoading,
            child: Text(submitLabel),
          ),
        ],
      ),
    );
  }
}
