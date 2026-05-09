import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:paypalm/services/palm_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PalmScanScreen extends StatefulWidget {
  final bool isRegistration;
  final double? billAmount;

  const PalmScanScreen({
    super.key, 
    required this.isRegistration,
    this.billAmount,
  });

  @override
  State<PalmScanScreen> createState() => _PalmScanScreenState();
}

class _PalmScanScreenState extends State<PalmScanScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isBusy = false;
  bool _flashOn = false;
  final PalmAuthService _palmService = PalmAuthService();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _checkEnrollmentStatus();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0, end: 380).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkEnrollmentStatus() async {
    if (widget.isRegistration) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['palmRegistered'] == true) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1F2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('✅ Already Enrolled', style: TextStyle(color: Colors.white)),
              content: const Text(
                'You have already registered your palm! You can now use it to authorize payments securely.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Pop dialog
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'palmRegistered': false});
                    _initCamera();
                  },
                  child: const Text('Delete & Rescan', style: TextStyle(color: Colors.redAccent)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Pop dialog
                    Navigator.of(context).pop(); // Pop screen
                  },
                  child: const Text('OK', style: TextStyle(color: Color(0xFF00E5FF))),
                ),
              ],
            ),
          );
          return; // Stop here, don't initialize camera
        }
      }
    }
    // If not registered or is authentication, start camera
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_flashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() => _flashOn = !_flashOn);
    } catch (e) {
      debugPrint('Flash error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flash not supported on this device: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    setState(() => _isBusy = true);

    try {
      final XFile photo = await _controller!.takePicture();
      final File imageFile = File(photo.path);

      Map<String, dynamic> result;
      if (widget.isRegistration) {
        // Automatically use logged-in user's name/email
        final String name = user.displayName ??
            user.email ??
            'User_${user.uid.substring(0, 5)}';
        result = await _palmService.register(
          fullName: name,
          email: user.email,
          palmImage: imageFile,
        );
      } else {
        if (widget.billAmount != null) {
          result = await _palmService.simulateTransaction(
            palmImage: imageFile,
            amount: widget.billAmount!,
            recipient: user.displayName ?? 'Merchant',
          );
        } else {
          result = await _palmService.authenticate(
            palmImage: imageFile,
          );
        }
      }

      if (!mounted) return;
      _showResult(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showResult(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          result['status'] == 'success' || result['matched'] == true
              ? '✅ Success'
              : '❌ Failed',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result['full_name'] != null)
              Text('User: ${result['full_name']}',
                  style: const TextStyle(color: Colors.white70)),
            if (result['user_name'] != null)
              Text('User: ${result['user_name']}',
                  style: const TextStyle(color: Colors.white70)),
            if (result['confidence'] != null)
              Text(
                  'Confidence: ${(result['confidence'] as num).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white70)),
            if (result['message'] != null)
              Text('Message: ${result['message']}',
                  style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Pop dialog
              Navigator.of(context).pop(); // Pop screen
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            Text(widget.isRegistration ? 'Enroll Palm' : 'Authenticate Palm'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          // Flashlight toggle
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 20,
            child: IconButton(
              onPressed: _toggleFlash,
              icon: Icon(
                _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: Colors.white,
                size: 30,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.4),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
          // Scanning Frame Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 280,
                      height: 380,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF00E5FF).withOpacity(0.8),
                            width: 2),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Stack(
                              children: [
                                Positioned(
                                  top: _animation.value,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E5FF),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00E5FF).withOpacity(0.8),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Position your palm inside the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Capture Button
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _isBusy ? null : _captureAndProcess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  widget.isRegistration ? 'ENROLL NOW' : 'SCAN TO PAY',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // Processing Overlay
          if (_isBusy)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF00E5FF),
                        strokeWidth: 5,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Processing Palm...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Verifying biometric features',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
