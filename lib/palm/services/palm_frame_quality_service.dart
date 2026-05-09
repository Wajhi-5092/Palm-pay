import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:paypalm/palm/services/palm_landmark_model.dart';

/// Focus / blur + exposure heuristics on the Y-plane palm ROI.
///
/// Thresholds skew toward budget sensors and soft sharpening — stricter tuning
/// can be re-enabled for high-accuracy kiosk devices.
class PalmFrameQualityResult {
  PalmFrameQualityResult({
    required this.laplacianVariance,
    required this.meanLuma,
    required this.edgeEnergy,
    required this.localContrast,
    this.reason,
  });

  final double laplacianVariance;
  final double meanLuma;

  /// Normalized mean gradient magnitude in [0, ~1].
  final double edgeEnergy;

  /// Coefficient of variation of luminance (texture / vignetting proxy).
  final double localContrast;
  final String? reason;

  bool get isAcceptable => reason == null;
}

class PalmFrameQualityService {
  /// Soft-camera friendly (was 14).
  static const double minLaplacianVar = 6.0;

  /// Allow slightly dim sensors (was 45).
  static const double minMeanLuma = 38.0;
  static const double maxMeanLuma = 248.0;

  /// Minimum normalized edge strength (was 0.08) — coarse gradients help weak optics.
  static const double minEdgeEnergy = 0.026;

  /// If edges are marginal, variance of luminance patches can still indicate usable detail.
  static const double minLocalContrast = 0.028;

  PalmFrameQualityResult evaluate({
    required CameraImage image,
    required List<PalmLm> landmarks,
  }) {
    final w = image.width;
    final h = image.height;
    final yPlane = image.planes.first;
    final rowStride = yPlane.bytesPerRow;
    final bytes = yPlane.bytes;

    var nMinX = 1.0, nMaxX = 0.0, nMinY = 1.0, nMaxY = 0.0;
    for (final p in landmarks) {
      nMinX = math.min(nMinX, p.x);
      nMaxX = math.max(nMaxX, p.x);
      nMinY = math.min(nMinY, p.y);
      nMaxY = math.max(nMaxY, p.y);
    }

    const pad = 0.035;
    final ix0 = math.max(0, math.min(w - 2, ((nMinX - pad) * w).floor()));
    final ix1 = math.max(1, math.min(w - 1, ((nMaxX + pad) * w).ceil()));
    final iy0 = math.max(0, math.min(h - 2, ((nMinY - pad) * h).floor()));
    final iy1 = math.max(1, math.min(h - 1, ((nMaxY + pad) * h).ceil()));

    /// Easier minimum box on tiny preview resolutions (budget phones).
    if (ix1 - ix0 < 18 || iy1 - iy0 < 18) {
      return PalmFrameQualityResult(
        laplacianVariance: 0,
        meanLuma: 0,
        edgeEnergy: 0,
        localContrast: 0,
        reason: 'Move closer — palm too small in frame.',
      );
    }

    final samples = <int>[];
    final lapVals = <double>[];
    var sumY = 0.0;
    var count = 0;
    var gradSum = 0.0;

    for (var y = iy0; y < iy1; y += 2) {
      for (var x = ix0; x < ix1; x += 2) {
        final yv = _y(bytes, rowStride, x, y);
        samples.add(yv);
        sumY += yv;
        count++;

        final xr = math.min(w - 1, x + 1);
        final xml = math.max(0, x - 1);
        final yd = math.min(h - 1, y + 1);
        final yu = math.max(0, y - 1);

        final gxFine =
            (_y(bytes, rowStride, xr, y) - _y(bytes, rowStride, xml, y))
                .toDouble() /
                2.0;
        final gyFine =
            (_y(bytes, rowStride, x, yd) - _y(bytes, rowStride, x, yu))
                .toDouble() /
                2.0;

        final xr2 = math.min(w - 1, x + 2);
        final xml2 = math.max(0, x - 2);
        final yd2 = math.min(h - 1, y + 2);
        final yu2 = math.max(0, y - 2);

        final gxWide =
            (_y(bytes, rowStride, xr2, y) - _y(bytes, rowStride, xml2, y))
                .toDouble() /
                4.0;
        final gyWide =
            (_y(bytes, rowStride, x, yd2) - _y(bytes, rowStride, x, yu2))
                .toDouble() /
                4.0;

        final gx = math.max(gxFine.abs(), gxWide.abs());
        final gy = math.max(gyFine.abs(), gyWide.abs());

        gradSum += math.sqrt(gx * gx + gy * gy);
      }
    }

    for (var i = 1; i < samples.length - 1; i++) {
      final lap = samples[i - 1].toDouble() +
          samples[i + 1].toDouble() -
          2 * samples[i].toDouble();
      lapVals.add(lap.abs());
    }

    final meanLuma = sumY / (count + 1e-6);
    final lapVariance = lapVals.isEmpty
        ? 0.0
        : _variance(lapVals);
    final edgeEnergy = gradSum / (count + 1e-6) / 255.0;
    final lumaStd = _stdDevInt(samples);
    final localContrast = lumaStd / (meanLuma + 1e-6);

    final edgeNorm = edgeEnergy;

    if (meanLuma < minMeanLuma || meanLuma > maxMeanLuma) {
      return PalmFrameQualityResult(
        laplacianVariance: lapVariance,
        meanLuma: meanLuma,
        edgeEnergy: edgeNorm,
        localContrast: localContrast,
        reason: 'Lighting issue — aim for softer, even light.',
      );
    }
    if (lapVariance < minLaplacianVar) {
      return PalmFrameQualityResult(
        laplacianVariance: lapVariance,
        meanLuma: meanLuma,
        edgeEnergy: edgeNorm,
        localContrast: localContrast,
        reason: 'Image looks blurry — hold the phone steadier.',
      );
    }

    /// Accept if gradients are okay, or if gradients are marginal but luminance variation
    /// (palm ridges / shading) still shows enough structure on soft cameras.
    final textureWeak = edgeNorm < minEdgeEnergy;
    final contrastPoor = localContrast < minLocalContrast;
    final borderlineContrast =
        edgeNorm >= minEdgeEnergy * 0.72 && localContrast >= minLocalContrast * 0.85;

    if (textureWeak && contrastPoor && !borderlineContrast) {
      return PalmFrameQualityResult(
        laplacianVariance: lapVariance,
        meanLuma: meanLuma,
        edgeEnergy: edgeNorm,
        localContrast: localContrast,
        reason: 'Increase light or move slightly closer — camera signal is faint.',
      );
    }

    return PalmFrameQualityResult(
      laplacianVariance: lapVariance,
      meanLuma: meanLuma,
      edgeEnergy: edgeNorm,
      localContrast: localContrast,
    );
  }

  double _variance(List<double> v) {
    if (v.isEmpty) return 0;
    final m = v.reduce((a, b) => a + b) / v.length;
    var s = 0.0;
    for (final x in v) {
      final d = x - m;
      s += d * d;
    }
    return s / v.length;
  }

  double _stdDevInt(List<int> xs) {
    if (xs.isEmpty) return 0;
    final m = xs.reduce((a, b) => a + b) / xs.length;
    var s = 0.0;
    for (final x in xs) {
      final d = x - m;
      s += d * d;
    }
    return math.sqrt(s / xs.length);
  }

  int _y(Uint8List bytes, int rowStride, int x, int y) {
    final i = y * rowStride + x;
    if (i < 0 || i >= bytes.lengthInBytes) return 0;
    return bytes[i];
  }
}
