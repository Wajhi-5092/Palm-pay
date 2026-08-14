import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:paypalm/palm/services/palm_landmark_model.dart';

class PalmScanOverlay extends StatelessWidget {
  const PalmScanOverlay({
    super.key,
    required this.hands,
    required this.controller,
    required this.phaseLabel,
    required this.distanceHint,
    required this.progress,
    required this.hintColor,
    this.warnMessage,
  });

  final List<List<PalmLm>> hands;
  final CameraController controller;
  final String phaseLabel;
  final String distanceHint;
  final double progress;
  final Color hintColor;
  final String? warnMessage;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _PalmMeshPainter(
            hands: hands,
            previewSize: previewSize,
            lensDirection: controller.description.lensDirection,
            sensorOrientation: controller.description.sensorOrientation,
          ),
        ),
        CustomPaint(
          painter: _GuideOvalPainter(
            color: hintColor.withValues(alpha: 0.45),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phaseLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      distanceHint,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(hintColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (warnMessage != null) ...[
                const SizedBox(height: 10),
                _glass(
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: hintColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warnMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _glass({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class _GuideOvalPainter extends CustomPainter {
  _GuideOvalPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.46),
      width: size.width * 0.72,
      height: size.height * 0.55,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _GuideOvalPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PalmMeshPainter extends CustomPainter {
  _PalmMeshPainter({
    required this.hands,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
  });

  final List<List<PalmLm>> hands;
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;

  static const List<List<int>> _connections = [
    [0, 1], [1, 2], [2, 3], [3, 4],
    [0, 5], [5, 6], [6, 7], [7, 8],
    [5, 9], [9, 10], [10, 11], [11, 12],
    [9, 13], [13, 14], [14, 15], [15, 16],
    [13, 17], [17, 18], [18, 19], [19, 20], [0, 17],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final logicalWidth = previewSize.width;
    final logicalHeight = previewSize.height;
    final scale = size.width / previewSize.height;

    canvas.save();

    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sensorOrientation * math.pi / 180);

    if (lensDirection == CameraLensDirection.front) {
      canvas.scale(-1, 1);
      canvas.rotate(math.pi);
    }

    canvas.scale(scale);

    final linePaint = Paint()
      ..color = const Color(0xFF5CE1E6)
      ..strokeWidth = 3 / scale
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..style = PaintingStyle.fill;

    for (final hand in hands) {
      for (final c in _connections) {
        if (c[0] >= hand.length || c[1] >= hand.length) continue;
        final a = hand[c[0]];
        final b = hand[c[1]];
        final p1 = Offset(
          (a.x - 0.5) * logicalWidth,
          (a.y - 0.5) * logicalHeight,
        );
        final p2 = Offset(
          (b.x - 0.5) * logicalWidth,
          (b.y - 0.5) * logicalHeight,
        );
        canvas.drawLine(p1, p2, linePaint);
      }
      for (final lm in hand) {
        final p = Offset(
          (lm.x - 0.5) * logicalWidth,
          (lm.y - 0.5) * logicalHeight,
        );
        canvas.drawCircle(p, 5 / scale, nodePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PalmMeshPainter oldDelegate) {
    if (oldDelegate.hands.length != hands.length) return true;
    if (hands.isEmpty) return false;
    if (oldDelegate.hands.first.length != hands.first.length) return true;
    if (hands.first.isEmpty) return false;
    final a = oldDelegate.hands.first[0];
    final b = hands.first[0];
    return (a.x - b.x).abs() > 0.008 || (a.y - b.y).abs() > 0.008;
  }
}
