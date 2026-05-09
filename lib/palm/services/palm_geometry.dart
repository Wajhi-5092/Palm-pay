import 'dart:math' as math;

import 'package:paypalm/palm/services/palm_landmark_model.dart';

double dist2(PalmLm a, PalmLm b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return dx * dx + dy * dy;
}

double dist(PalmLm a, PalmLm b) => math.sqrt(dist2(a, b));

/// Rough palm width estimate (normalized image coordinates).
double palmWidth(List<PalmLm> lm) {
  return dist(lm[5], lm[17]) + 1e-6;
}

double fingerExtensionRatio(List<PalmLm> lm) {
  const tips = [4, 8, 12, 16, 20];
  final w = lm[0];
  final pw = palmWidth(lm);
  var sum = 0.0;
  for (final t in tips) {
    sum += dist(lm[t], w);
  }
  return (sum / tips.length) / pw;
}

/// Palm tangent angle in the image plane (radians).
double palmTangentAngle(List<PalmLm> lm) {
  final dx = lm[17].x - lm[5].x;
  final dy = lm[17].y - lm[5].y;
  return math.atan2(dy, dx);
}

/// Normalized axis-aligned bbox area covering all landmarks [0–1]^2 domain.
double palmCoverageArea(List<PalmLm> lm) {
  var minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
  for (final p in lm) {
    minX = math.min(minX, p.x);
    maxX = math.max(maxX, p.x);
    minY = math.min(minY, p.y);
    maxY = math.max(maxY, p.y);
  }
  return (maxX - minX).clamp(0.0, 1.0) * (maxY - minY).clamp(0.0, 1.0);
}
