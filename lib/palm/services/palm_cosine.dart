import 'dart:math' as math;

/// Cosine similarity in [0, 1] for same-length numeric vectors.
double palmCosineSimilarity(List<double> a, List<double> b) {
  final n = math.min(a.length, b.length);
  if (n == 0) return 0;
  double dot = 0, na = 0, nb = 0;
  for (var i = 0; i < n; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  final denom = math.sqrt(na) * math.sqrt(nb) + 1e-10;
  final sim = dot / denom;
  return sim.clamp(-1.0, 1.0);
}
