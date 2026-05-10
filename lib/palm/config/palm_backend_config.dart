import 'package:flutter/foundation.dart';

/// URLs, regions, and toggles for optional **Firebase Callable** palm APIs
/// (`functions/index.js`). The app’s default palm flow uses
/// [PalmSimpleFirestoreService] only; enable callables if you wire the scanner
/// to Functions again.
class PalmBackendConfig {
  PalmBackendConfig._();

  /// Matches `firebase-functions` `region` in `functions/index.js` (`us-central1`).
  static const String functionsRegion = String.fromEnvironment(
    'PALM_FUNCTIONS_REGION',
    defaultValue: 'us-central1',
  );

  /// Optional **Cloud Run** palm HTTPS API (Bearer). Used only if you integrate HTTP.
  static String? get cloudRunPalmApiBaseUrl {
    const raw = String.fromEnvironment('PALM_API_BASE_URL', defaultValue: '');
    final t = raw.trim();
    if (t.isEmpty) return null;
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }

  /// When `false`, skip callable setup (Firestore-only mode).
  static const bool useFirebaseCallablePalm = bool.fromEnvironment(
    'PALM_USE_CALLABLES',
    defaultValue: false,
  );

  static void debugLogConfig() {
    if (!kDebugMode) return;
    debugPrint(
      '[PalmBackendConfig] region=$functionsRegion '
      'callables=$useFirebaseCallablePalm '
      'cloudRun=${cloudRunPalmApiBaseUrl ?? '(none)'}',
    );
  }
}
