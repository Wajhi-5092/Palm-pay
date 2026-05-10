import 'dart:async';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paypalm/palm/data/palm_simple_firestore_service.dart';
import 'package:paypalm/palm/services/mediapipe_hand_engine.dart';
import 'package:paypalm/palm/services/palm_embedding_service.dart';
import 'package:paypalm/palm/services/palm_frame_quality_service.dart';
import 'package:paypalm/palm/services/palm_geometry.dart';
import 'package:paypalm/palm/services/palm_liveness_tracker.dart';
import 'package:paypalm/palm/services/palm_stub_embedding.dart';
import 'package:paypalm/palm/ui/palm_data_recovery_dialog.dart';
import 'package:paypalm/palm/ui/palm_merchant_customer_confirm_screen.dart';
import 'package:paypalm/palm/ui/widgets/palm_scan_overlay.dart';
import 'package:paypalm/widgets/custom_snackbar.dart';

enum PalmScannerPurpose {
  registration,
  userVerification,
  merchantCheckout,
}

class PalmScannerScreen extends StatefulWidget {
  const PalmScannerScreen({
    super.key,
    required this.purpose,
    this.checkoutAmount,
    this.checkoutSessionId,
  });

  final PalmScannerPurpose purpose;
  final double? checkoutAmount;
  /// Merchant billing session (one per "Scan to Charge"); used to prevent duplicate customer scans.
  final String? checkoutSessionId;

  @override
  State<PalmScannerScreen> createState() => _PalmScannerScreenState();
}

class _PalmScannerScreenState extends State<PalmScannerScreen> {
  static const double _matchThreshold = 0.95;

  final MediapipeHandEngine _engine = MediapipeHandEngine();
  final PalmEmbeddingService _embedding = PalmEmbeddingService();
  final PalmFrameQualityService _qualityGate = PalmFrameQualityService();
  final PalmLivenessTracker _liveness = PalmLivenessTracker();
  CameraController? _camera;
  bool _simpleMode = false;
  List<CameraDescription> _cameras = [];
  CameraLensDirection _activeLens = CameraLensDirection.front;
  bool _hasFrontCamera = false;
  bool _hasBackCamera = false;
  bool _ready = false;
  bool _switchingLens = false;
  bool _frameBusy = false;
  bool _processing = false;

  List<List<PalmLm>> _hands = [];
  String _phaseMessage = 'Searching for your palm…';
  String _distanceHint = 'Center your open palm in the oval.';
  String? _warn;
  double _progress = 0;
  int _steadyFrames = 0;
  bool _livenessDone = false;
  bool _torchOn = false;

  Future<void> _torchOffSilently() async {
    final c = _camera;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.setFlashMode(FlashMode.off);
    } catch (_) {}
    if (mounted && _torchOn) {
      setState(() => _torchOn = false);
    }
  }

  Future<void> _setTorch(bool on) async {
    final c = _camera;
    if (c == null || !c.value.isInitialized || _switchingLens) return;
    if (_activeLens != CameraLensDirection.back) return;

    try {
      await c.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchOn = on);
    } catch (_) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'This camera does not support the flashlight.',
          type: SnackbarType.warning,
        );
        setState(() => _torchOn = false);
      }
      try {
        await c.setFlashMode(FlashMode.off);
      } catch (_) {}
    }
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  CameraLensDirection _preferredLensForPurpose() {
    return widget.purpose == PalmScannerPurpose.merchantCheckout
        ? CameraLensDirection.back
        : CameraLensDirection.front;
  }

  CameraLensDirection _pickInitialLens() {
    final want = _preferredLensForPurpose();
    final hasWant =
        _cameras.any((c) => c.lensDirection == want);
    if (hasWant) return want;
    return _cameras.first.lensDirection;
  }

  void _resetScanProgress() {
    _hands = [];
    _warn = null;
    _progress = 0;
    _steadyFrames = 0;
    _liveness.reset();
    _livenessDone = false;
    _phaseMessage = 'Searching for your palm…';
    _distanceHint = 'Center your open palm in the oval.';
  }

  Future<void> _disposeCameraController() async {
    final cam = _camera;
    _camera = null;
    if (cam == null) return;
    if (cam.value.isStreamingImages) {
      await cam.stopImageStream();
    }
    await cam.dispose();
  }

  Future<void> _startCameraForLens(CameraLensDirection lens) async {
    late CameraDescription camDesc;
    try {
      camDesc = _cameras.firstWhere((c) => c.lensDirection == lens);
    } catch (_) {
      camDesc = _cameras.first;
    }
    _activeLens = camDesc.lensDirection;

    _camera = CameraController(
      camDesc,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _camera!.initialize();
    await _camera!.setFocusMode(FocusMode.auto);
    await _camera!.setExposureMode(ExposureMode.auto);
    await _camera!.setFlashMode(FlashMode.off);
    await _camera!.startImageStream(_onCameraImage);
  }

  Future<void> _switchLens(CameraLensDirection lens) async {
    if (_cameras.length < 2) return;
    if (!_simpleMode && !_engine.isSupported) return;
    if (_processing ||
        _switchingLens ||
        !_cameras.any((c) => c.lensDirection == lens)) {
      return;
    }
    if (lens == _activeLens) return;

    setState(() {
      _switchingLens = true;
      _torchOn = false;
      _resetScanProgress();
    });

    await _torchOffSilently();
    await _disposeCameraController();
    try {
      if (_simpleMode) {
        await _startSimpleCameraForLens(lens);
      } else {
        await _engine.init();
        await _startCameraForLens(lens);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: e.toString().replaceAll('Exception: ', ''),
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _switchingLens = false);
      }
    }
  }

  Future<void> _bootstrapSimple() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw CameraException('none', 'No cameras found');

      _hasFrontCamera = _cameras
          .any((c) => c.lensDirection == CameraLensDirection.front);
      _hasBackCamera = _cameras
          .any((c) => c.lensDirection == CameraLensDirection.back);

      await _startSimpleCameraForLens(_pickInitialLens());

      if (mounted) {
        setState(() {
          _ready = true;
          _simpleMode = true;
          _phaseMessage = 'Ready to capture';
          _distanceHint = kIsWeb
              ? 'Frame your palm, then tap the button (Chrome camera).'
              : 'Frame your palm, then tap the button to save.';
        });
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _ready = true;
          _warn = e.description ?? 'Camera error';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ready = true;
          _warn = e.toString();
        });
      }
    }
  }

  Future<void> _startSimpleCameraForLens(CameraLensDirection lens) async {
    late CameraDescription camDesc;
    try {
      camDesc = _cameras.firstWhere((c) => c.lensDirection == lens);
    } catch (_) {
      camDesc = _cameras.first;
    }
    _activeLens = camDesc.lensDirection;

    final format = kIsWeb ? ImageFormatGroup.jpeg : ImageFormatGroup.yuv420;

    _camera = CameraController(
      camDesc,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: format,
    );

    await _camera!.initialize();
    await _camera!.setFocusMode(FocusMode.auto);
    await _camera!.setExposureMode(ExposureMode.auto);
    await _camera!.setFlashMode(FlashMode.off);
  }

  Future<void> _bootstrap() async {
    if (kIsWeb || !_engine.isSupported) {
      await _bootstrapSimple();
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw CameraException('none', 'No cameras found');

      _hasFrontCamera = _cameras
          .any((c) => c.lensDirection == CameraLensDirection.front);
      _hasBackCamera = _cameras
          .any((c) => c.lensDirection == CameraLensDirection.back);

      _activeLens = _pickInitialLens();
      await _engine.init();
      await _startCameraForLens(_activeLens);

      if (mounted) {
        setState(() {
          _ready = true;
          _simpleMode = false;
          _phaseMessage = 'Searching for your palm…';
        });
      }
    } on CameraException catch (e) {
      await _disposeCameraController();
      if (mounted) {
        setState(() {
          _ready = true;
          _warn = e.description ?? 'Camera error';
        });
      }
    } catch (e) {
      await _disposeCameraController();
      if (mounted) {
        setState(() {
          _ready = true;
          _warn = e.toString();
        });
      }
    }
  }

  String _friendlyError(Object e) {
    if (e is FirebaseException) {
      return e.message?.trim().isNotEmpty == true ? e.message! : e.code;
    }
    if (e is StateError) {
      return e.message;
    }
    return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }

  Future<void> _finishWithEmbedding(Float32List embedding) async {
    try {
      switch (widget.purpose) {
        case PalmScannerPurpose.registration:
          await PalmSimpleFirestoreService.saveUserPalmScan(
            embedding: embedding,
            biometricHash: PalmEmbeddingService.biometricHash(embedding),
          );
          if (!mounted) return;
          Navigator.of(context).pop(true);
        case PalmScannerPurpose.userVerification:
          final matched = await PalmSimpleFirestoreService.verifyLocally(
            probe: embedding,
            threshold: _matchThreshold,
          );
          if (!mounted) return;
          if (matched) {
            Navigator.of(context).pop(true);
          } else {
            CustomSnackbar.show(
              context: context,
              message: 'No match — enroll first or retry.',
              type: SnackbarType.error,
            );
            if (_simpleMode) {
              if (mounted) setState(() => _processing = false);
            } else {
              await _restartPreview();
            }
          }
        case PalmScannerPurpose.merchantCheckout:
          final amount = widget.checkoutAmount ?? 0;
          if (amount <= 0) throw StateError('Invalid amount');
          final merchantUid = FirebaseAuth.instance.currentUser?.uid;
          final match = await PalmSimpleFirestoreService.findBestCustomerMatch(
            embedding,
            excludeUid: merchantUid,
            threshold: PalmSimpleFirestoreService.merchantMatchThreshold,
          );
          if (!mounted) return;
          if (match == null) {
            CustomSnackbar.show(
              context: context,
              message:
                  'No matching customer found. Ask them to enroll their palm in PayPalm first.',
              type: SnackbarType.error,
            );
            if (_simpleMode) {
              if (mounted) setState(() => _processing = false);
            } else {
              await _restartPreview();
            }
            return;
          }
          final sessionId = widget.checkoutSessionId?.trim();
          if (sessionId != null &&
              sessionId.isNotEmpty &&
              merchantUid != null) {
            final already = await PalmSimpleFirestoreService
                .hasCustomerCompletedCheckoutSessionScan(
              merchantUid: merchantUid,
              checkoutSessionId: sessionId,
              customerUid: match.uid,
            );
            if (!mounted) return;
            if (already) {
              CustomSnackbar.show(
                context: context,
                message: PalmSimpleFirestoreService
                    .palmCheckoutDuplicateCustomerMessage,
                type: SnackbarType.error,
              );
              if (_simpleMode) {
                if (mounted) setState(() => _processing = false);
              } else {
                await _restartPreview();
              }
              return;
            }
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => PalmMerchantCustomerConfirmScreen(
                match: match,
                amount: amount,
                embedding: embedding,
                checkoutSessionId: widget.checkoutSessionId,
              ),
            ),
          );
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      await showPalmFirestoreRecoveryDialog(
        context: context,
        message: _friendlyError(e),
        merchantFlow: widget.purpose == PalmScannerPurpose.merchantCheckout,
      );
      if (!mounted) return;
      if (_simpleMode) {
        setState(() => _processing = false);
      } else {
        await _restartPreview();
      }
    }
  }

  Future<void> _simpleCaptureAndSave() async {
    if (_camera == null || !_camera!.value.isInitialized || _processing) {
      return;
    }
    setState(() => _processing = true);
    await _torchOffSilently();
    try {
      final shot = await _camera!.takePicture();
      final bytes = await shot.readAsBytes();
      final emb = stubEmbeddingFromImageBytes(bytes);
      await _finishWithEmbedding(emb);
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: _friendlyError(e),
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_simpleMode) return;
    if (!_ready ||
        _processing ||
        _switchingLens ||
        _camera == null ||
        _frameBusy) {
      return;
    }
    if (!_engine.isSupported) return;

    _frameBusy = true;
    try {
      final orient = _camera!.description.sensorOrientation;
      final hands = _engine.detect(image, orient);

      if (!mounted) return;

      setState(() => _hands = hands);

      if (hands.length > 1) {
        setState(() {
          _warn = 'Only one palm should be visible.';
          _progress = 0;
          _steadyFrames = 0;
          _liveness.reset();
          _livenessDone = false;
        });
        return;
      }

      if (hands.isEmpty) {
        setState(() {
          _warn = null;
          _phaseMessage = 'Searching for your palm…';
          _distanceHint = 'Show your full open palm inside the guide.';
          _progress = 0;
          _steadyFrames = 0;
          _liveness.reset();
          _livenessDone = false;
        });
        return;
      }

      final lm = hands.first;
      if (lm.length < 21) return;

      final coverage = palmCoverageArea(lm);
      final ext = fingerExtensionRatio(lm);

      String? localWarn;
      if (ext < 0.58) {
        localWarn = 'Open your fingers fully — avoid a fist.';
      } else if (coverage < 0.09) {
        localWarn = 'Move a little closer — palm too small.';
      } else if (coverage > 0.56) {
        localWarn = 'Move slightly back — palm too large.';
      }

      final q = _qualityGate.evaluate(image: image, landmarks: lm);
      if (!q.isAcceptable) {
        localWarn = q.reason;
      }

      if (localWarn != null) {
        setState(() {
          _warn = localWarn;
          _phaseMessage = 'Adjust your hand';
          _distanceHint = 'Follow the live outline for alignment.';
          _progress = 0;
          _steadyFrames = 0;
        });
        return;
      }

      setState(() {
        _warn = null;
        _phaseMessage = 'Palm detected';
        _distanceHint = _distanceCopyForCoverage(coverage);
      });

      _liveness.onFrame(lm);

      if (!_livenessDone) {
        setState(() {
          _phaseMessage = 'Liveness check';
          _distanceHint = 'Slowly rotate or tilt your palm left ↔ right.';
          _progress = (_liveness.passedRotationCue(minDeltaRad: 0.11) ? 0.55 : 0.25);
        });
        if (_liveness.passedRotationCue(minDeltaRad: 0.11)) {
          _livenessDone = true;
          _steadyFrames = 0;
        }
        return;
      }

      if (!_liveness.isStableHold()) {
        setState(() {
          _phaseMessage = 'Hold still';
          _distanceHint = 'Relax — keep the palm inside the oval.';
          _progress = 0.65;
          _steadyFrames = 0;
        });
        return;
      }

      _steadyFrames++;
      setState(() {
        _phaseMessage = 'Hold still';
        _distanceHint = 'Capturing secure template…';
        _progress = 0.65 + (_steadyFrames / 18).clamp(0, 1) * 0.3;
      });

      if (_steadyFrames >= 15) {
        _processing = true;
        await _finalizeCapture(image, lm);
      }
    } finally {
      _frameBusy = false;
    }
  }

  String _distanceCopyForCoverage(double coverage) {
    if (coverage < 0.13) return 'Distance • a bit closer for sharper ridges.';
    if (coverage > 0.42) return 'Distance • ease back slightly for full palm.';
    return 'Distance • optimal range';
  }

  Future<void> _finalizeCapture(CameraImage image, List<PalmLm> lm) async {
    if (_camera == null) {
      _processing = false;
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (widget.purpose != PalmScannerPurpose.merchantCheckout &&
        user == null) {
      _processing = false;
      CustomSnackbar.show(
        context: context,
        message: 'Please sign in first.',
        type: SnackbarType.error,
      );
      await _restartPreview();
      return;
    }
    if (widget.purpose == PalmScannerPurpose.merchantCheckout && user == null) {
      _processing = false;
      CustomSnackbar.show(
        context: context,
        message: 'Merchant session required.',
        type: SnackbarType.error,
      );
      await _restartPreview();
      return;
    }

    setState(() {
      _phaseMessage = 'Processing';
      _distanceHint = 'Saving to Firestore…';
      _progress = 1;
    });

    await _torchOffSilently();
    await _camera!.stopImageStream();

    try {
      final embedding = _embedding.buildTemplate(
        landmarks: lm,
        yuvImage: image,
      );
      await _finishWithEmbedding(embedding);
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: _friendlyError(e),
          type: SnackbarType.error,
        );
        await _restartPreview();
      }
    }
  }

  Future<void> _restartPreview() async {
    _processing = false;
    _resetScanProgress();
    final cam = _camera;
    if (cam != null && cam.value.isInitialized && !cam.value.isStreamingImages) {
      try {
        await cam.startImageStream(_onCameraImage);
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final c = _camera;
    if (c != null && c.value.isInitialized) {
      unawaited(
        c.setFlashMode(FlashMode.off).then((_) {}, onError: (_) {}),
      );
    }
    _camera?.dispose();
    _camera = null;
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.purpose) {
      PalmScannerPurpose.registration => 'Register Palm',
      PalmScannerPurpose.userVerification => 'Palm Verify',
      PalmScannerPurpose.merchantCheckout => 'Customer Palm Pay',
    };

    if (!_ready || _camera == null || !_camera!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_simpleMode) {
      final previewSize = _camera!.value.previewSize!;
      final ratio = previewSize.height / previewSize.width;
      final canSwitch = _hasFrontCamera && _hasBackCamera;

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          actions: [
            if (_hasBackCamera && _activeLens == CameraLensDirection.back)
              Tooltip(
                message:
                    _torchOn ? 'Turn flashlight off' : 'Turn flashlight on',
                child: IconButton(
                  icon: Icon(
                    _torchOn
                        ? Icons.flashlight_on
                        : Icons.flashlight_off_rounded,
                  ),
                  color: _torchOn ? const Color(0xFFFFCC4D) : Colors.white70,
                  onPressed: (_processing || _switchingLens)
                      ? null
                      : () => _setTorch(!_torchOn),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            if (_warn != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _warn!,
                  style: const TextStyle(color: Colors.orangeAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: ratio,
                  child: CameraPreview(_camera!),
                ),
              ),
            ),
            if (canSwitch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SegmentedButton<CameraLensDirection>(
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<CameraLensDirection>(
                      value: CameraLensDirection.front,
                      label: Text('Front'),
                      icon: Icon(Icons.camera_front_rounded, size: 18),
                    ),
                    ButtonSegment<CameraLensDirection>(
                      value: CameraLensDirection.back,
                      label: Text('Back'),
                      icon: Icon(Icons.camera_rear_rounded, size: 18),
                    ),
                  ],
                  selected: {_activeLens},
                  emptySelectionAllowed: false,
                  onSelectionChanged: (selected) async {
                    if (selected.isEmpty || _processing || _switchingLens) {
                      return;
                    }
                    await _switchLens(selected.first);
                    if (mounted) setState(() {});
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: (_processing || _switchingLens)
                      ? null
                      : _simpleCaptureAndSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3A86FF),
                  ),
                  child: Text(
                    _processing ? 'Saving…' : 'Capture & save palm scan',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                kIsWeb
                    ? 'Chrome: allow camera when prompted. Data saves to Firestore under your user.'
                    : 'Saves palm scan to Firestore on your account (demo).',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final previewSize = _camera!.value.previewSize!;
    final ratio = previewSize.height / previewSize.width;

    final canSwitch = _hasFrontCamera && _hasBackCamera;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_hasBackCamera && _activeLens == CameraLensDirection.back)
            Tooltip(
              message:
                  _torchOn ? 'Turn flashlight off' : 'Turn flashlight on',
              child: IconButton(
                icon: Icon(
                  _torchOn ? Icons.flashlight_on : Icons.flashlight_off_rounded,
                ),
                color: _torchOn ? const Color(0xFFFFCC4D) : Colors.white70,
                onPressed: (_processing || _switchingLens)
                    ? null
                    : () => _setTorch(!_torchOn),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: ratio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_camera!),
                        PalmScanOverlay(
                          hands: _hands,
                          controller: _camera!,
                          phaseLabel: _phaseMessage,
                          distanceHint: _distanceHint,
                          progress: _progress,
                          hintColor: const Color(0xFF5CE1E6),
                          warnMessage: _warn,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_switchingLens)
                  ColoredBox(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(color: Color(0xFF5CE1E6)),
                          SizedBox(height: 12),
                          Text(
                            'Switching camera…',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (canSwitch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.center,
                child: SegmentedButton<CameraLensDirection>(
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<CameraLensDirection>(
                      value: CameraLensDirection.front,
                      label: Text('Front'),
                      icon: Icon(Icons.camera_front_rounded, size: 18),
                    ),
                    ButtonSegment<CameraLensDirection>(
                      value: CameraLensDirection.back,
                      label: Text('Back'),
                      icon: Icon(Icons.camera_rear_rounded, size: 18),
                    ),
                  ],
                  selected: {_activeLens},
                  emptySelectionAllowed: false,
                  onSelectionChanged: (selected) async {
                    if (selected.isEmpty || _processing || _switchingLens) {
                      return;
                    }
                    await _switchLens(selected.first);
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white54),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live hand tracking (Android). Embedding saved to Firestore on your user.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
