import 'package:cloud_functions/cloud_functions.dart';
import 'package:paypalm/palm/data/palm_api_exception.dart';

/// Maps [FirebaseFunctionsException] (and related failures) to [PalmApiException]
/// and user-facing strings for snackbars.
class PalmCallableError {
  PalmCallableError._();

  static PalmApiException fromFirebaseFunctions(
    FirebaseFunctionsException e,
  ) {
    return PalmApiException(
      code: e.code,
      message: e.message,
      details: e.details,
    );
  }

  /// Short message suitable for UI when you only have [Object].
  static String userMessage(Object error) {
    if (error is PalmApiException) {
      return friendlyForCode(error.code, fallback: error.message);
    }
    if (error is FirebaseFunctionsException) {
      return friendlyForCode(error.code, fallback: error.message);
    }
    final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    final lower = raw.toLowerCase();
    if (_looksLikeTransportFailure(lower)) {
      return _paymentConnectionGuidance;
    }
    return raw;
  }

  static const String _paymentConnectionGuidance =
      'Payment could not complete. Check your connection and try again.';

  static bool _looksLikeTransportFailure(String lower) {
    const hints = <String>[
      'unable to establish',
      'failed to connect',
      'connection',
      'socket',
      'network',
      'host lookup',
      'timed out',
      'timeout',
      'dns',
      'no address',
      'unreachable',
      'handshake',
      'grpc',
    ];
    for (final h in hints) {
      if (lower.contains(h)) return true;
    }
    return false;
  }

  /// Whether to retry a callable (e.g. [finalizePalmPayment]) — transient gRPC/channel/network issues.
  static bool shouldRetryCallable(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
        case 'aborted':
        case 'resource-exhausted':
          return true;
        default:
          return false;
      }
    }
    return _looksLikeTransportFailure(error.toString().toLowerCase());
  }

  /// Maps non-[FirebaseFunctionsException] failures (e.g. gRPC channel errors) to [PalmApiException].
  static PalmApiException fromTransportFailure(Object e) {
    final raw = e.toString();
    final lower = raw.toLowerCase();
    if (_looksLikeTransportFailure(lower)) {
      return PalmApiException(
        code: 'unavailable',
        message: _paymentConnectionGuidance,
        cause: e,
      );
    }
    return PalmApiException(code: 'internal', message: raw, cause: e);
  }

  static String friendlyForCode(String code, {String? fallback}) {
    switch (code) {
      case 'unauthenticated':
        return 'Please sign in to use palm verification.';
      case 'permission-denied':
        return 'You do not have permission for this palm action.';
      case 'invalid-argument':
        return fallback?.isNotEmpty == true
            ? fallback!
            : 'Invalid palm data. Try scanning again.';
      case 'failed-precondition':
        return fallback?.isNotEmpty == true
            ? fallback!
            : 'Palm service is not ready. Try again later.';
      case 'not-found':
        if (fallback != null && fallback.trim().isNotEmpty) {
          return fallback;
        }
        return 'Palm service not found. Check deployment.';
      case 'internal':
        return fallback?.isNotEmpty == true
            ? fallback!
            : 'Palm service error. Try again.';
      case 'unavailable':
        if (fallback != null && fallback.trim().isNotEmpty) {
          return fallback;
        }
        return 'Palm service is temporarily unavailable.';
      case 'deadline-exceeded':
        return 'Request timed out. Try again.';
      case 'resource-exhausted':
        return 'Too many requests. Try again in a moment.';
      default:
        final t = fallback?.trim();
        return (t != null && t.isNotEmpty)
            ? t
            : 'Something went wrong ($code).';
    }
  }
}
