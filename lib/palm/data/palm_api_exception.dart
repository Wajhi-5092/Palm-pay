/// Error returned from palm backend (Cloud Functions, HTTP, or local validation).
class PalmApiException implements Exception {
  PalmApiException({
    required this.code,
    this.message,
    this.details,
    this.cause,
  });

  /// Firebase `HttpsError` code or HTTP status key (e.g. `unauthenticated`).
  final String code;

  /// Human-readable message from the server, if any.
  final String? message;

  /// Optional structured payload (callable `details`).
  final Object? details;

  final Object? cause;

  @override
  String toString() {
    final m = message?.trim();
    if (m != null && m.isNotEmpty) return 'PalmApiException($code): $m';
    return 'PalmApiException($code)';
  }
}
