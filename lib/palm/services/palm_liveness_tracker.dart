import 'dart:collection';
import 'dart:math' as math;

import 'package:paypalm/palm/services/palm_geometry.dart';
import 'package:paypalm/palm/services/palm_landmark_model.dart';

/// Motion + rotation cues to reduce static replay spoofing.
class PalmLivenessTracker {
  final int _maxSamples = 48;
  final Queue<double> _wristX = Queue();
  final Queue<double> _wristY = Queue();
  final Queue<double> _angles = Queue();

  void reset() {
    _wristX.clear();
    _wristY.clear();
    _angles.clear();
  }

  void onFrame(List<PalmLm> landmarks) {
    final w = landmarks[0];
    _push(_wristX, w.x);
    _push(_wristY, w.y);
    _push(_angles, palmTangentAngle(landmarks));
  }

  void _push(Queue<double> q, double v) {
    q.addLast(v);
    while (q.length > _maxSamples) {
      q.removeFirst();
    }
  }

  bool get hasStableBaseline => _wristX.length >= 16;

  /// Low wrist jitter (~hold still gate).
  bool isStableHold({double maxStdNorm = 0.014}) {
    if (_wristX.length < 12) return false;
    return _stdDev(_wristX) < maxStdNorm && _stdDev(_wristY) < maxStdNorm;
  }

  /// Enough angular change after prompting user to tilt palm.
  bool passedRotationCue({required double minDeltaRad}) {
    if (_angles.length < 24) return false;
    final first = _angles.first;
    var maxDelta = 0.0;
    for (final a in _angles) {
      maxDelta =
          math.max(maxDelta, _angleDiffRad(a, first).abs());
    }
    return maxDelta >= minDeltaRad;
  }

  double _stdDev(Iterable<double> xs) {
    final list = xs.toList();
    if (list.isEmpty) return 0;
    final m =
        list.reduce((a, b) => a + b) / list.length;
    var s = 0.0;
    for (final x in list) {
      final d = x - m;
      s += d * d;
    }
    return math.sqrt(s / list.length);
  }

  double _angleDiffRad(double a, double b) {
    var d = a - b;
    while (d > math.pi) {
      d -= 2 * math.pi;
    }
    while (d < -math.pi) {
      d += 2 * math.pi;
    }
    return d;
  }
}
