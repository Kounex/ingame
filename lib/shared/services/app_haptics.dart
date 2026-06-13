import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef AppHapticCallback = Future<void> Function();

class AppHaptics {
  const AppHaptics({
    this.isWeb = kIsWeb,
    this.platform,
    this.selectionCallback = HapticFeedback.selectionClick,
    this.lightImpactCallback = HapticFeedback.lightImpact,
    this.mediumImpactCallback = HapticFeedback.mediumImpact,
  });

  final bool isWeb;
  final TargetPlatform? platform;
  final AppHapticCallback selectionCallback;
  final AppHapticCallback lightImpactCallback;
  final AppHapticCallback mediumImpactCallback;

  bool get _isSupportedMobilePlatform {
    if (isWeb) return false;
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    return resolvedPlatform == TargetPlatform.iOS ||
        resolvedPlatform == TargetPlatform.android;
  }

  Future<void> selection() async {
    if (!_isSupportedMobilePlatform) return;
    try {
      await selectionCallback();
    } catch (_) {}
  }

  Future<void> success() async {
    if (!_isSupportedMobilePlatform) return;
    try {
      await lightImpactCallback();
    } catch (_) {}
  }

  Future<void> destructiveConfirm() async {
    if (!_isSupportedMobilePlatform) return;
    try {
      await mediumImpactCallback();
    } catch (_) {}
  }
}

final appHapticsProvider = Provider<AppHaptics>((_) => const AppHaptics());
