import 'package:flutter_riverpod/legacy.dart';

final authInvalidationSignalProvider = StateProvider<int>((ref) => 0);
final sessionResetSignalProvider = StateProvider<int>((ref) => 0);
final logoutRedirectPendingProvider = StateProvider<bool>((ref) => false);
