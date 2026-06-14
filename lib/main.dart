import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/firebase_config.dart';
import 'core/storage/preferences.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseOptions = FirebaseConfig.webOptions;
  if (!kIsWeb || firebaseOptions != null) {
    try {
      await Firebase.initializeApp(options: firebaseOptions);
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  }
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        preferencesProvider
            .overrideWithValue(PreferencesService(prefs)),
      ],
      child: const InGameApp(),
    ),
  );
}
