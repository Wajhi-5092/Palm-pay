import 'package:camera/camera.dart';

import 'palm_landmark_model.dart';

/// Web: no JNI MediaPipe.
class MediapipeHandEngine {
  bool get isSupported => false;

  Future<void> init() async {}

  void dispose() {}

  List<List<PalmLm>> detect(CameraImage image, int sensorOrientation) => [];
}
