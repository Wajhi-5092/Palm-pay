import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSessionService {
  // Encrypted local session metadata.
  static const String _idTokenKey = 'auth_session_id_token';
  static const String _tokenExpiryMsKey = 'auth_session_token_expiry_ms';

  // App-level session expiry used for offline mode + inactivity enforcement.
  static const String _appSessionExpiryMsKey = 'auth_app_session_expiry_ms';
  static const String _lastActivityMsKey = 'auth_last_activity_ms';

  static const String _pendingRefreshKey = 'auth_pending_refresh';
  static const String _uidKey = 'auth_session_uid';

  final FlutterSecureStorage _secureStorage;

  // Offline allowance for mPIN gate while still considered a valid session.
  // You can tune this later; for now it matches "cached session exists".
  static const Duration appSessionTtl = Duration(days: 7);

  AuthSessionService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  int? _decodeJwtExpMillis(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payloadJson) as Map<String, dynamic>;
      final expSeconds = map['exp'];
      if (expSeconds is int) return expSeconds * 1000;
      if (expSeconds is double) return (expSeconds * 1000).toInt();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> persistSessionFromUser(
    User user, {
    required bool pendingRefresh,
  }) async {
    final idTokenResult = await user.getIdTokenResult();
    final idToken = idTokenResult.token;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Failed to obtain Firebase idToken');
    }
    final tokenExpiryMs = idTokenResult.expirationTime?.millisecondsSinceEpoch;
    final parsedExpMs = tokenExpiryMs ?? _decodeJwtExpMillis(idToken);

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final appExpiryMs = nowMs + appSessionTtl.inMilliseconds;

    await _secureStorage.write(key: _idTokenKey, value: idToken);
    if (parsedExpMs != null) {
      await _secureStorage.write(key: _tokenExpiryMsKey, value: parsedExpMs.toString());
    } else {
      await _secureStorage.delete(key: _tokenExpiryMsKey);
    }
    await _secureStorage.write(key: _appSessionExpiryMsKey, value: appExpiryMs.toString());
    await _secureStorage.write(key: _lastActivityMsKey, value: nowMs.toString());
    await _secureStorage.write(key: _pendingRefreshKey, value: pendingRefresh ? 'true' : 'false');
    await _secureStorage.write(key: _uidKey, value: user.uid);
  }

  Future<void> touchActivity() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _secureStorage.write(key: _lastActivityMsKey, value: nowMs.toString());
  }

  Future<int?> getLastActivityMs() async {
    final v = await _secureStorage.read(key: _lastActivityMsKey);
    return v != null ? int.tryParse(v) : null;
  }

  Future<bool> hasValidCachedSession() async {
    final raw = await _secureStorage.read(key: _appSessionExpiryMsKey);
    if (raw == null) return false;
    final expiryMs = int.tryParse(raw);
    if (expiryMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch < expiryMs;
  }

  Future<bool> isAppSessionExpired() async {
    final ok = await hasValidCachedSession();
    return !ok;
  }

  Future<int?> getRemainingAppSessionMs() async {
    final raw = await _secureStorage.read(key: _appSessionExpiryMsKey);
    final expiryMs = raw != null ? int.tryParse(raw) : null;
    if (expiryMs == null) return null;
    final remaining = expiryMs - DateTime.now().millisecondsSinceEpoch;
    return remaining;
  }

  Future<bool> getPendingRefresh() async {
    final v = await _secureStorage.read(key: _pendingRefreshKey);
    return v == 'true';
  }

  Future<void> setPendingRefresh(bool pending) async {
    await _secureStorage.write(
      key: _pendingRefreshKey,
      value: pending ? 'true' : 'false',
    );
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _idTokenKey);
    await _secureStorage.delete(key: _tokenExpiryMsKey);
    await _secureStorage.delete(key: _appSessionExpiryMsKey);
    await _secureStorage.delete(key: _lastActivityMsKey);
    await _secureStorage.delete(key: _pendingRefreshKey);
    await _secureStorage.delete(key: _uidKey);
  }

  Future<void> tryRefreshSessionIfNeeded({required bool isOnline}) async {
    if (!isOnline) return;
    final pending = await getPendingRefresh();
    if (!pending) return;

    // During widget tests (or early app boot), Firebase may not be initialized yet.
    if (Firebase.apps.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await persistSessionFromUser(user, pendingRefresh: false);
  }
}

