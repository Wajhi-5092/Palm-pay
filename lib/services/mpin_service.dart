import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MpinVerificationState {
  valid,
  invalid,
  locked,
  notConfigured,
}

class MpinVerificationResult {
  final MpinVerificationState state;
  final int? remainingSeconds;
  final int? failedAttempts;

  const MpinVerificationResult({
    required this.state,
    this.remainingSeconds,
    this.failedAttempts,
  });
}

class MpinService {
  // Legacy keys kept only for one-time migration.
  static const String _legacyMpinKey = 'user_mpin';
  static const String _legacyEnabledOnReopenKey = 'mpin_enabled_on_reopen';

  // Secure storage keys (encrypted).
  static const String _mpinHashKey = 'mpin_hash';
  static const String _mpinSaltKey = 'mpin_salt';
  static const String _mpinLengthKey = 'mpin_length';

  static const String _enabledOnReopenKey = 'mpin_enabled_on_reopen_secure';
  static const String _failedAttemptsKey = 'mpin_failed_attempts';
  static const String _lockedUntilMsKey = 'mpin_locked_until_ms';

  static const int _maxFailedAttempts = 5;
  static const Duration _lockDuration = Duration(seconds: 30);

  final FlutterSecureStorage _secureStorage;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  MpinService({
    FlutterSecureStorage? secureStorage,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _firestore = firestore,
        _auth = auth;

  FirebaseAuth? get _effectiveAuth {
    if (_auth != null) return _auth;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance;
  }

  FirebaseFirestore? get _effectiveFirestore {
    if (_firestore != null) return _firestore;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  Future<void> _ensureLegacyMigration() async {
    // If we already have a configured MPIN in secure storage, there's nothing to do.
    final existingHash = await _secureStorage.read(key: _mpinHashKey);
    if (existingHash != null && existingHash.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final legacyMpin = prefs.getString(_legacyMpinKey);
    final legacyEnabled = prefs.getBool(_legacyEnabledOnReopenKey) ?? false;

    // If no legacy MPIN exists, skip migration.
    if (legacyMpin == null || legacyMpin.isEmpty) return;
    if (!(legacyMpin.length == 4 || legacyMpin.length == 6)) return;
    if (!RegExp(r'^\d+$').hasMatch(legacyMpin)) return;

    // Hash the legacy MPIN and store only the hash+salt securely.
    final saltBytes = _generateSaltBytes();
    final salt = base64UrlEncode(saltBytes);
    final hash = _hashMpin(mpin: legacyMpin, salt: salt);

    await _secureStorage.write(key: _mpinSaltKey, value: salt);
    await _secureStorage.write(key: _mpinHashKey, value: hash);
    await _secureStorage.write(key: _mpinLengthKey, value: legacyMpin.length.toString());
    await _secureStorage.write(key: _enabledOnReopenKey, value: legacyEnabled ? 'true' : 'false');

    // Remove raw MPIN from shared preferences.
    await prefs.remove(_legacyMpinKey);
  }

  static List<int> _generateSaltBytes([int length = 16]) {
    final rng = Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }

  static String _hashMpin({required String mpin, required String salt}) {
    // Hash format: SHA-256(salt:mpin). No raw MPIN stored.
    final bytes = utf8.encode('$salt:$mpin');
    return sha256.convert(bytes).toString();
  }

  Future<int?> _readInt(String key) async {
    final v = await _secureStorage.read(key: key);
    if (v == null) return null;
    return int.tryParse(v);
  }

  Future<void> _resetLockoutIfAny() async {
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _lockedUntilMsKey);
  }

  Future<bool> hasMpin() async {
    await _ensureLegacyMigration();
    final hash = await _secureStorage.read(key: _mpinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<int> getMpinLength() async {
    await _ensureLegacyMigration();
    final raw = await _secureStorage.read(key: _mpinLengthKey);
    final parsed = raw != null ? int.tryParse(raw) : null;
    if (parsed == 4 || parsed == 6) return parsed!;
    return 0;
  }

  Future<bool> isEnabledOnReopen() async {
    await _ensureLegacyMigration();
    // If secure storage is missing, fall back to legacy shared pref (but migration removes legacy MPIN).
    final v = await _secureStorage.read(key: _enabledOnReopenKey);
    if (v == null) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_legacyEnabledOnReopenKey) ?? false;
    }
    return v == 'true';
  }

  Future<void> setEnabledOnReopen(bool enabled) async {
    await _ensureLegacyMigration();
    await _secureStorage.write(
      key: _enabledOnReopenKey,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<void> setMpin(String mpin) async {
    await _ensureLegacyMigration();

    final trimmed = mpin.trim();
    final length = trimmed.length;
    if (!(length == 4 || length == 6)) {
      throw ArgumentError('MPIN must be 4 or 6 digits');
    }
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      throw ArgumentError('MPIN must contain only digits');
    }

    final saltBytes = _generateSaltBytes();
    final salt = base64UrlEncode(saltBytes);
    final hash = _hashMpin(mpin: trimmed, salt: salt);

    await _secureStorage.write(key: _mpinSaltKey, value: salt);
    await _secureStorage.write(key: _mpinHashKey, value: hash);
    await _secureStorage.write(key: _mpinLengthKey, value: length.toString());

    // Also persist the hashed MPIN metadata to Firestore for cross-device support.
    // NOTE: We store ONLY salt+hash, never raw MPIN.
    final auth = _effectiveAuth;
    final firestore = _effectiveFirestore;
    final user = auth?.currentUser;
    if (user != null && firestore != null) {
      await firestore.collection('users').doc(user.uid).set({
        'mpin': {
          'salt': salt,
          'hash': hash,
          'length': length,
        },
      }, SetOptions(merge: true));
    }

    // Reset lockout state after MPIN change.
    await _resetLockoutIfAny();
  }

  Future<MpinVerificationResult> verifyMpin(String input) async {
    await _ensureLegacyMigration();
    final configuredHash = await _secureStorage.read(key: _mpinHashKey);
    final salt = await _secureStorage.read(key: _mpinSaltKey);
    final configuredLength = await getMpinLength();

    if (configuredHash == null || configuredHash.isEmpty || salt == null) {
      return const MpinVerificationResult(state: MpinVerificationState.notConfigured);
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lockedUntilMs = await _readInt(_lockedUntilMsKey);
    if (lockedUntilMs != null && nowMs < lockedUntilMs) {
      final remainingSeconds =
          ((lockedUntilMs - nowMs) / 1000).ceil();
      return MpinVerificationResult(
        state: MpinVerificationState.locked,
        remainingSeconds: remainingSeconds,
        failedAttempts: await _readInt(_failedAttemptsKey),
      );
    }

    final trimmed = input.trim();
    if (trimmed.length != configuredLength || !RegExp(r'^\d+$').hasMatch(trimmed)) {
      // Treat as invalid input but still keep lockout counters.
      return _handleInvalidAttemptAndMaybeLock(trimmedLengthMismatch: true);
    }

    final candidateHash = _hashMpin(mpin: trimmed, salt: salt);
    if (!_constantTimeEquals(configuredHash, candidateHash)) {
      return _handleInvalidAttemptAndMaybeLock();
    }

    await _resetLockoutIfAny();
    return const MpinVerificationResult(state: MpinVerificationState.valid);
  }

  Future<MpinVerificationResult> _handleInvalidAttemptAndMaybeLock({
    bool trimmedLengthMismatch = false,
  }) async {
    final attempts = (await _readInt(_failedAttemptsKey)) ?? 0;
    final nextAttempts = attempts + 1;

    if (nextAttempts >= _maxFailedAttempts) {
      final lockedUntilMs = DateTime.now().add(_lockDuration).millisecondsSinceEpoch;
      await _secureStorage.write(key: _failedAttemptsKey, value: nextAttempts.toString());
      await _secureStorage.write(key: _lockedUntilMsKey, value: lockedUntilMs.toString());
      return MpinVerificationResult(
        state: MpinVerificationState.locked,
        remainingSeconds: _lockDuration.inSeconds,
        failedAttempts: nextAttempts,
      );
    }

    await _secureStorage.write(key: _failedAttemptsKey, value: nextAttempts.toString());
    return MpinVerificationResult(
      state: MpinVerificationState.invalid,
      failedAttempts: nextAttempts,
    );
  }

  Future<int> getFailedAttempts() async {
    await _ensureLegacyMigration();
    return (await _readInt(_failedAttemptsKey)) ?? 0;
  }

  /// Returns remaining lock seconds. Returns 0 when not locked.
  Future<int> getLockRemainingSeconds() async {
    await _ensureLegacyMigration();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lockedUntilMs = await _readInt(_lockedUntilMsKey);
    if (lockedUntilMs == null || nowMs >= lockedUntilMs) return 0;
    return ((lockedUntilMs - nowMs) / 1000).ceil();
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  Future<void> removeMpin() async {
    // Remove secure MPIN first.
    await _secureStorage.delete(key: _mpinHashKey);
    await _secureStorage.delete(key: _mpinSaltKey);
    await _secureStorage.delete(key: _mpinLengthKey);
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _lockedUntilMsKey);
    await _secureStorage.write(key: _enabledOnReopenKey, value: 'false');

    // Remove legacy raw MPIN if it still exists (best-effort).
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyMpinKey);
    await prefs.setBool(_legacyEnabledOnReopenKey, false);

    // Remove hashed MPIN metadata from Firestore as well.
    final auth = _effectiveAuth;
    final firestore = _effectiveFirestore;
    final user = auth?.currentUser;
    if (user != null && firestore != null) {
      await firestore.collection('users').doc(user.uid).set({
        'mpin': FieldValue.delete(),
      }, SetOptions(merge: true));
    }
  }
}
