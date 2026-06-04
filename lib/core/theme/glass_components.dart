import 'dart:ui';

import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/tappable.dart';
import 'app_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.animate = false,
    this.animationDelay = Duration.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool animate;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);

    final Widget card = Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppColors.glassBlurRadius,
            sigmaY: AppColors.glassBlurRadius,
          ),
          child: Tappable(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: radius,
                border: Border.all(color: AppColors.glassBorder),
              ),
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (animate) {
      return _FadeScaleIn(delay: animationDelay, child: card);
    }
    return card;
  }
}

class _FadeScaleIn extends StatefulWidget {
  const _FadeScaleIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeScaleIn> createState() => _FadeScaleInState();
}

class _FadeScaleInState extends State<_FadeScaleIn> {
  @override
  Widget build(BuildContext context) {
    return Cue.onMount(
      motion: .easeOut(350.ms),
      child: Actor(
        delay: widget.delay,
        acts: [const .fadeIn(), const .scale(from: 0.96)],
        child: widget.child,
      ),
    );
  }
}

enum GlassButtonVariant { primary, secondary, ghost }

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = GlassButtonVariant.primary,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final GlassButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    switch (variant) {
      case GlassButtonVariant.primary:
        return _PrimaryButton(
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
          child: child,
        );
      case GlassButtonVariant.secondary:
        return _SecondaryButton(
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
          child: child,
        );
      case GlassButtonVariant.ghost:
        return _GhostButton(
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
          child: child,
        );
    }
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.onPressed,
    required this.isLoading,
    required this.child,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading ? _loadingIndicator(AppColors.background) : child,
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.onPressed,
    required this.isLoading,
    required this.child,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlurRadius,
          sigmaY: AppColors.glassBlurRadius,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.glassSurfaceLight,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.glassBorder),
            ),
          ),
          child: isLoading ? _loadingIndicator(AppColors.textPrimary) : child,
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.onPressed,
    required this.isLoading,
    required this.child,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading ? _loadingIndicator(AppColors.textPrimary) : child,
    );
  }
}

Widget _loadingIndicator(Color color) {
  return SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(color),
    ),
  );
}

class GlassInput extends StatelessWidget {
  const GlassInput({
    super.key,
    this.controller,
    this.validator,
    this.errorText,
    this.label,
    this.hint,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? errorText;
  final String? label;
  final String? hint;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      forceErrorText: errorText,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textTertiary)
            : null,
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        filled: true,
        fillColor: AppColors.glassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textTertiary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
