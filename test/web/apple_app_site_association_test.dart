import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'apple app site association only keeps invite universal-link path',
    () async {
      final rawJson = await File(
        'web/.well-known/apple-app-site-association',
      ).readAsString();
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final details = decoded['applinks']!['details']! as List<dynamic>;
      final firstDetail = details.first as Map<String, dynamic>;
      final paths = (firstDetail['paths'] as List<dynamic>).cast<String>();

      expect(paths, contains('/join/*'));
      expect(paths, isNot(contains('/auth/steam-callback.html')));
    },
  );
}
