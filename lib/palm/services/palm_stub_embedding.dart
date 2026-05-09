import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Web / fallback: deterministic pseudo-embedding from image bytes (no hand landmarks).
Float32List stubEmbeddingFromImageBytes(List<int> bytes) {
  final h = sha256.convert(bytes).bytes;
  final out = Float32List(128);
  for (var i = 0; i < 128; i++) {
    final b1 = h[i % h.length];
    final b2 = h[(i + 13) % h.length];
    out[i] = ((b1 / 255.0) * 2 - 1 + (b2 / 255.0) * 2 - 1) / 2;
  }
  var s = 0.0;
  for (final x in out) {
    s += x * x;
  }
  final n = math.sqrt(s) + 1e-8;
  for (var i = 0; i < out.length; i++) {
    out[i] /= n;
  }
  return out;
}
