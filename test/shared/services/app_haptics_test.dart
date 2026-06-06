import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/shared/services/app_haptics.dart';

void main() {
  test('app haptics no-op on unsupported platforms', () async {
    var selectionCalls = 0;
    var lightCalls = 0;
    var mediumCalls = 0;
    final haptics = AppHaptics(
      isWeb: true,
      platform: TargetPlatform.android,
      selectionCallback: () async => selectionCalls++,
      lightImpactCallback: () async => lightCalls++,
      mediumImpactCallback: () async => mediumCalls++,
    );

    await haptics.selection();
    await haptics.success();
    await haptics.refreshComplete();
    await haptics.destructiveConfirm();

    expect(selectionCalls, 0);
    expect(lightCalls, 0);
    expect(mediumCalls, 0);
  });

  test('app haptics map semantic intents to mobile callbacks', () async {
    var selectionCalls = 0;
    var lightCalls = 0;
    var mediumCalls = 0;
    final haptics = AppHaptics(
      isWeb: false,
      platform: TargetPlatform.android,
      selectionCallback: () async => selectionCalls++,
      lightImpactCallback: () async => lightCalls++,
      mediumImpactCallback: () async => mediumCalls++,
    );

    await haptics.selection();
    await haptics.success();
    await haptics.refreshComplete();
    await haptics.destructiveConfirm();

    expect(selectionCalls, 1);
    expect(lightCalls, 2);
    expect(mediumCalls, 1);
  });
}
