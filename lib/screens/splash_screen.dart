import 'dart:async';
import 'package:flutter/material.dart';
import 'package:paypalm/widgets/common/soft_blob.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paypalm/services/auth_service.dart';
import 'auth_choice_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
    _startNav();
  }

  void _startNav() {
    _timer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) _goNext();
    });
  }

  Future<void> _goNext() async {
    if (!mounted) return;

    // Drop stale auth when the account was removed from Firebase (Console / Admin SDK).
    await AuthService().syncSignedInUserWithServer(
      FirebaseAuth.instance.currentUser,
    );

    if (!mounted) return;

    // Always land on role choice after splash (user picks Personal vs Merchant).
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => const AuthChoiceScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandTeal = Color(0xFF00D1B2);
    const bg = Color(0xFF0F172A);

    final size = MediaQuery.of(context).size;
    final height = size.height;

    final isSmall = height < 650;

    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 🔵 Top Glow
              Positioned(
                top: -constraints.maxHeight * 0.15,
                left: -constraints.maxWidth * 0.2,
                child: SoftBlob(
                  size: constraints.maxWidth * 0.8,
                  color: brandTeal.withValues(alpha: 0.12),
                ),
              ),

              // 🔵 Bottom Glow
              Positioned(
                bottom: -constraints.maxHeight * 0.15,
                right: -constraints.maxWidth * 0.2,
                child: SoftBlob(
                  size: constraints.maxWidth * 0.8,
                  color: const Color(0xFF3A86FF).withValues(alpha: 0.12),
                ),
              ),

              // ✅ TRUE CENTER (no drift)
              Align(
                alignment: Alignment.center,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    return FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _scale,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        padding: EdgeInsets.all(isSmall ? 14 : 18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: brandTeal.withValues(alpha: 0.25),
                              blurRadius: isSmall ? 25 : 35,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.bolt_rounded,
                          size: isSmall ? 50 : 65,
                          color: brandTeal,
                        ),
                      ),

                      SizedBox(height: height * 0.035),

                      // Title (perfect center)
                      Text(
                        'PAYPALM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 20 : 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: isSmall ? 6 : 10,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'FUTURE OF PAYMENTS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: isSmall ? 9 : 11,
                          letterSpacing: isSmall ? 2 : 4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔻 Bottom loader (always safe)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: constraints.maxHeight * 0.06,
                  ),
                  child: SizedBox(
                    width: isSmall ? 30 : 40,
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      color: brandTeal.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
