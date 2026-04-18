// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Mobile uses local config files by default, so we return a placeholder
    // or you can configure this completely properly with `flutterfire configure`.
    return const FirebaseOptions(
      apiKey: "AIzaSyDZdnS4FWO0HaC6_I8Ta8NER1YRvGVimNo",
      appId: "1:261667843517:web:ad37cafbe1b39d425b36d4",
      messagingSenderId: "261667843517",
      projectId: "m-9f5e8",
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB_GES4fhFG86K8Px3tVNDswnaTpKH1bUM',
    appId:
        '1:261667843517:web:ad37cafbe1b39d425b36d4', // MUST REPLACE THIS OR RUN flutterfire configure
    messagingSenderId: '261667843517',
    projectId: 'm-9f5e8',
    storageBucket: 'm-9f5e8.firebasestorage.app',
  );
}
