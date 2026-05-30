import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/user_model.dart';
import '../../data/profile_repository.dart';

class ProfileNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      return await repo.getProfile();
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(profileRepositoryProvider);
      return await repo.getProfile();
    });
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(profileRepositoryProvider);
      return await repo.updateProfile(updates);
    });
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, User?>(ProfileNotifier.new);
