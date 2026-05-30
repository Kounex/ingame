import 'dart:async';
import 'dart:ui';

import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';

enum AppToastType { success, error, info, warning }

class AppToast {
  AppToast._();

  static const _animationDuration = Duration(milliseconds: 260);
  static OverlayEntry? _currentEntry;
  static ValueNotifier<bool>? _visibilityNotifier;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    _removeCurrent(immediate: true);

    final overlay = Overlay.of(context, rootOverlay: true);
    final visibility = ValueNotifier<bool>(false);

    final entry = OverlayEntry(
      builder: (_) =>
          _ToastOverlay(message: message, type: type, visibility: visibility),
    );

    _currentEntry = entry;
    _visibilityNotifier = visibility;
    overlay.insert(entry);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_visibilityNotifier == visibility) {
        visibility.value = true;
      }
    });

    _dismissTimer = Timer(duration, () {
      if (_visibilityNotifier == visibility) {
        visibility.value = false;
        Timer(_animationDuration, () {
          if (_currentEntry == entry) {
            _removeCurrent(immediate: true);
          }
        });
      }
    });
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(context, message, type: AppToastType.success, duration: duration);
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
  }) {
    show(context, message, type: AppToastType.error, duration: duration);
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(context, message, type: AppToastType.info, duration: duration);
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(context, message, type: AppToastType.warning, duration: duration);
  }

  static void _removeCurrent({required bool immediate}) {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (!immediate) {
      _visibilityNotifier?.value = false;
      return;
    }

    _visibilityNotifier?.dispose();
    _visibilityNotifier = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastOverlay extends StatelessWidget {
  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.visibility,
  });

  final String message;
  final AppToastType type;
  final ValueNotifier<bool> visibility;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ValueListenableBuilder<bool>(
                valueListenable: visibility,
                builder: (context, isVisible, child) {
                  return Cue.onToggle(
                    toggled: isVisible,
                    motion: const .easeOut(AppToast._animationDuration),
                    reverseMotion: const .easeOut(AppToast._animationDuration),
                    acts: [const .fadeIn(), const .slideY(from: 0.12)],
                    child: child!,
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  child: _ToastCard(message: message, type: type),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.message, required this.type});

  final String message;
  final AppToastType type;

  Color get _accentColor => switch (type) {
    AppToastType.success => AppColors.success,
    AppToastType.error => AppColors.error,
    AppToastType.info => AppColors.primary,
    AppToastType.warning => AppColors.warning,
  };

  IconData get _icon => switch (type) {
    AppToastType.success => Icons.check_circle_rounded,
    AppToastType.error => Icons.error_rounded,
    AppToastType.info => Icons.info_rounded,
    AppToastType.warning => Icons.warning_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.lgBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlurRadius,
          sigmaY: AppColors.glassBlurRadius,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight.withValues(alpha: 0.92),
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: _accentColor.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 64,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.lg),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.14),
                          borderRadius: AppRadius.mdBorder,
                        ),
                        child: Icon(_icon, size: 18, color: _accentColor),
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
