import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/user_model.dart';
import '../../../profile/data/profile_repository.dart';

final memberProfileProvider =
    FutureProvider.family<User, String>((ref, userId) {
  return ref.read(profileRepositoryProvider).getUserById(userId);
});
