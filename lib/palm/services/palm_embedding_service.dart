import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:paypalm/palm/services/palm_geometry.dart';
import 'package:paypalm/palm/services/palm_landmark_model.dart';

/// Builds a fixed-size [embeddingDim] biometric vector from landmarks + coarse Y-plane texture.
///
/// This is a lightweight on-device embedding suited for cosine matching; swap in a TFLite CNN
/// embedding by replacing [buildTemplate] once a palmprint model is wired.
class PalmEmbeddingService {
  PalmEmbeddingService();

  static const int embeddingDim = 128;
  static const int textureBins = 64;
  static const int geomSlots = embeddingDim - textureBins;

  static final List<List<int>> _distancePairs = _buildPairs();

  static List<List<int>> _buildPairs() {
    const tips = [4, 8, 12, 16, 20];
    const mcps = [5, 9, 13, 17];
    final pairs = <List<int>>[];
    for (final t in tips) {
      pairs.add([0, t]);
    }
    for (var i = 0; i < mcps.length; i++) {
      for (var j = i + 1; j < mcps.length; j++) {
        pairs.add([mcps[i], mcps[j]]);
      }
    }
    pairs.add([5, 8]);
    pairs.add([9, 12]);
    pairs.add([13, 16]);
    pairs.add([17, 20]);
    for (var k = 0; k <= 15; k++) {
      pairs.add([k, (k + 4) % 21]);
    }
    return pairs;
  }

  Float32List buildTemplate({
    required List<PalmLm> landmarks,
    required CameraImage yuvImage,
  }) {
    final out = Float32List(embeddingDim);
    final scale = palmWidth(landmarks);

    var pi = 0;
    for (final pair in _distancePairs) {
      if (pi >= geomSlots) break;
      final a = landmarks[pair[0].clamp(0, 20)];
      final b = landmarks[pair[1].clamp(0, 20)];
      out[pi++] = dist(a, b) / scale;
    }

    final extras = [
      fingerExtensionRatio(landmarks),
      palmTangentAngle(landmarks) / math.pi,
      palmCoverageArea(landmarks),
      landmarks[12].z - landmarks[0].z,
      landmarks[8].z - landmarks[0].z,
      landmarks[16].z - landmarks[0].z,
    ];
    for (final e in extras) {
      if (pi >= geomSlots) break;
      out[pi++] = e;
    }

    while (pi < geomSlots) {
      out[pi++] = 0;
    }

    _fillTextureHistogram(
      landmarks: landmarks,
      image: yuvImage,
      out: out,
      offset: geomSlots,
    );

    _l2Normalize(out);
    return out;
  }

  static String biometricHash(Float32List v) {
    final bytes = Uint8List.view(v.buffer, v.offsetInBytes, v.lengthInBytes);
    return sha256.convert(bytes).toString();
  }

  void _fillTextureHistogram({
    required List<PalmLm> landmarks,
    required CameraImage image,
    required Float32List out,
    required int offset,
  }) {
    final hist = List<double>.filled(textureBins, 0);
    final w = image.width;
    final h = image.height;
    final yPlane = image.planes.first;
    final rowStride = yPlane.bytesPerRow;

    var minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
    for (final p in landmarks) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }

    const pad = 0.03;
    minX = (minX - pad).clamp(0.0, 1.0);
    maxX = (maxX + pad).clamp(0.0, 1.0);
    minY = (minY - pad).clamp(0.0, 1.0);
    maxY = (maxY + pad).clamp(0.0, 1.0);

    final stepX = math.max(
      1,
      (((maxX - minX) * w) / 18).floor(),
    );
    final stepY = math.max(
      1,
      (((maxY - minY) * h) / 18).floor(),
    );

    for (var ix = (minX * w).floor(); ix < (maxX * w).floor(); ix += stepX) {
      for (var iy = (minY * h).floor(); iy < (maxY * h).floor(); iy += stepY) {
        final cx = ix.clamp(0, w - 1);
        final cy = iy.clamp(0, h - 1);
        final yv =
            _sampleY(rowStride: rowStride, bytes: yPlane.bytes, x: cx, y: cy) /
                255.0;
        final bi = (yv * (textureBins - 1)).floor().clamp(0, textureBins - 1);
        hist[bi] += 1;
      }
    }

    final total = hist.fold<double>(0, (a, b) => a + b) + 1e-6;
    for (var i = 0; i < textureBins && offset + i < out.length; i++) {
      out[offset + i] = hist[i] / total;
    }
  }

  int _sampleY({
    required int rowStride,
    required Uint8List bytes,
    required int x,
    required int y,
  }) {
    final i = y * rowStride + x;
    if (i < 0 || i >= bytes.lengthInBytes) return 0;
    return bytes[i];
  }

  void _l2Normalize(Float32List v) {
    var s = 0.0;
    for (final x in v) {
      s += x * x;
    }
    final n = math.sqrt(s) + 1e-8;
    for (var i = 0; i < v.length; i++) {
      v[i] /= n;
    }
  }
}
