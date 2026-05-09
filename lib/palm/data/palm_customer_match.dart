/// Result of matching a scanned palm embedding against [palmLookup] profiles.
class PalmCustomerMatch {
  PalmCustomerMatch({
    required this.uid,
    required this.displayName,
    required this.similarity,
    this.phone,
    this.email,
    this.photoUrl,
    this.handId,
  });

  final String uid;
  final String displayName;
  final String? phone;
  final String? email;
  final String? photoUrl;
  /// Opaque palm enrollment ID stored in [palmLookup] (tied to the account).
  final String? handId;
  /// Cosine similarity in roughly [-1, 1]; typical matches are high positives.
  final double similarity;

  double get confidencePercent =>
      (similarity.clamp(-1.0, 1.0) * 100).clamp(0.0, 100.0);
}
