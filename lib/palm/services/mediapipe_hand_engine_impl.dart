import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:paypalm/palm/services/palm_landmark_model.dart';

/// Android MediaPipe Hand Landmarker (JNI).
class MediapipeHandEngine {
  HandLandmarkerPlugin? _plugin;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init() async {
    if (!Platform.isAndroid) return;
    _plugin?.dispose();
    _plugin = HandLandmarkerPlugin.create(
      numHands: 2,
      minHandDetectionConfidence: 0.72,
      delegate: HandLandmarkerDelegate.gpu,
    );
  }

  void dispose() {
    _plugin?.dispose();
    _plugin = null;
  }

  List<List<PalmLm>> detect(CameraImage image, int sensorOrientation) {
    final p = _plugin;
    if (!isSupported || p == null) return [];
    final hands = p.detect(image, sensorOrientation);
    return hands
        .map(
          (h) => h.landmarks
              .map((l) => PalmLm(l.x, l.y, l.z))
              .toList(growable: false),
        )
        .toList(growable: false);
  }
}
