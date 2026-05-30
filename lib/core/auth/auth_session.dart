import 'package:flutter_riverpod/flutter_riverpod.dart';

final authInvalidationSignalProvider = StateProvider<int>((ref) => 0);
