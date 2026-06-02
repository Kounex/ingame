import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

final needsOnboardingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.maybeWhen(
    data: (s) => s.maybeWhen(
      authenticated: (user) {
        final hasEmail = user.email != null && user.email!.trim().isNotEmpty;
        final hasBio = user.bio != null && user.bio!.isNotEmpty;
        return !hasEmail || !hasBio;
      },
      orElse: () => false,
    ),
    orElse: () => false,
  );
});
