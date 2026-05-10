import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paypalm/palm/config/palm_backend_config.dart';
import 'package:paypalm/palm/data/palm_api_exception.dart';
import 'package:paypalm/palm/data/palm_callable_error.dart';
import 'package:uuid/uuid.dart';

/// Calls Firebase **HTTPS callables** defined in `functions/index.js`:
/// `registerPalmTemplate`, `verifyOwnPalm`, `matchPalmTemplate`, `processPalmSale`,
/// `finalizePalmPayment`, `verifyPalm`.
///
/// Requires signed-in user (merchants for match/sale). Throws [PalmApiException]
/// on failure. Not used by the default [PalmSimpleFirestoreService] path unless
/// you switch the UI to these methods.
class PalmFunctionsService {
  PalmFunctionsService({
    FirebaseFunctions? functions,
  }) : _functions = functions ??
            FirebaseFunctions.instanceFor(region: PalmBackendConfig.functionsRegion);

  final FirebaseFunctions _functions;

  /// Longer than default (60s) to survive cold-starts; avoids premature gRPC timeouts.
  static const Duration _callableTimeout = Duration(seconds: 120);
  static const int _maxCallAttempts = 3;

  static List<num> _embeddingList(Float32List f) {
    return List<num>.generate(f.length, (i) => f[i]);
  }

  Future<Map<String, dynamic>> registerPalmTemplate({
    required Float32List embedding,
    required String biometricHash,
    Map<String, dynamic>? deviceInfo,
  }) async {
    _requireUser();
    return _call('registerPalmTemplate', {
      'embedding': _embeddingList(embedding),
      'biometricHash': biometricHash,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
    });
  }

  /// Verify palm against **encrypted server template** (`palmBiometric` field).
  Future<Map<String, dynamic>> verifyOwnPalm({
    required Float32List probe,
    double? threshold,
  }) async {
    _requireUser();
    return _call('verifyOwnPalm', {
      'embedding': _embeddingList(probe),
      if (threshold != null) 'threshold': threshold,
    });
  }

  /// Merchant: match customer by embedding (server-side decrypt + cosine).
  Future<Map<String, dynamic>> matchPalmTemplate({
    required Float32List probe,
    double? threshold,
  }) async {
    _requireUser();
    return _call('matchPalmTemplate', {
      'embedding': _embeddingList(probe),
      if (threshold != null) 'threshold': threshold,
    });
  }

  /// One **atomic** palm payment: server re-verifies embedding, then moves funds user → merchant.
  /// Sends a per-attempt idempotency id unless you pass [clientRequestId].
  Future<Map<String, dynamic>> finalizePalmPayment({
    required String customerUid,
    required double amount,
    required Float32List embedding,
    String? handId,
    double threshold = 0.85,
    String? clientRequestId,
    String? checkoutSessionId,
  }) async {
    _requireUser();
    final id = (clientRequestId != null && clientRequestId.trim().isNotEmpty)
        ? clientRequestId.trim()
        : const Uuid().v4();
    return _call('finalizePalmPayment', {
      'customerUid': customerUid,
      'amount': amount,
      'embedding': _embeddingList(embedding),
      if (handId != null && handId.isNotEmpty) 'handId': handId,
      'threshold': threshold,
      'clientRequestId': id,
      if (checkoutSessionId != null && checkoutSessionId.trim().isNotEmpty)
        'checkoutSessionId': checkoutSessionId.trim(),
    });
  }

  /// Merchant: charge customer wallet after palm match (see Functions impl).
  Future<Map<String, dynamic>> processPalmSale({
    required Float32List probe,
    required double amount,
    double? threshold,
    String? clientRequestId,
  }) async {
    _requireUser();
    return _call('processPalmSale', {
      'embedding': _embeddingList(probe),
      'amount': amount,
      if (threshold != null) 'threshold': threshold,
      if (clientRequestId != null) 'clientRequestId': clientRequestId,
    });
  }

  /// Smoke test: PALM_MASTER_KEY secret mounted.
  Future<Map<String, dynamic>> verifyPalmHealth() async {
    _requireUser();
    return _call('verifyPalm', {});
  }

  void _requireUser() {
    if (FirebaseAuth.instance.currentUser == null) {
      throw PalmApiException(
        code: 'unauthenticated',
        message: 'Not signed in.',
      );
    }
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    for (var attempt = 0; attempt < _maxCallAttempts; attempt++) {
      try {
        final callable = _functions.httpsCallable(
          name,
          options: HttpsCallableOptions(timeout: _callableTimeout),
        );
        final result = await callable.call(payload);
        final data = result.data;
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        return <String, dynamic>{'ok': true, 'data': data};
      } on FirebaseFunctionsException catch (e) {
        if (PalmCallableError.shouldRetryCallable(e) &&
            attempt < _maxCallAttempts - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: 400 * (attempt + 1)),
          );
          continue;
        }
        throw PalmCallableError.fromFirebaseFunctions(e);
      } catch (e) {
        if (PalmCallableError.shouldRetryCallable(e) &&
            attempt < _maxCallAttempts - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: 400 * (attempt + 1)),
          );
          continue;
        }
        throw PalmCallableError.fromTransportFailure(e);
      }
    }
    throw PalmApiException(
      code: 'internal',
      message: 'callable exhausted retries',
    );
  }
}
