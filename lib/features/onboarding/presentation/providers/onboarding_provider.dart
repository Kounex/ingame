import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

final needsOnboardingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.maybeWhen(
    data: (s) => s.maybeWhen(
      authenticated: (user) {
        final hasBio = user.bio != null && user.bio!.isNotEmpty;
        final hasGamingHours = user.preferredGamingHours != null &&
            user.preferredGamingHours!.isNotEmpty;
        return !hasBio || !hasGamingHours;
      },
      orElse: () => false,
    ),
    orElse: () => false,
  );
});
