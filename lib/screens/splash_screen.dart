import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:paypalm/services/mpin_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_choice_screen.dart';
import '../user/modules/security/mpin_unlock_screen.dart';
import '../user/screens/home_page.dart';

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
  final MpinService _mpinService = MpinService();

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
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final hasMpin = await _mpinService.hasMpin();
    final mpinOnReopen = await _mpinService.isEnabledOnReopen();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) =>
            isLoggedIn
                ? (hasMpin && mpinOnReopen
                    ? const MpinUnlockScreen()
                    : const HomePage())
                : const AuthChoiceScreen(),
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
                child: _Glow(
                  size: constraints.maxWidth * 0.8,
                  color: brandTeal.withValues(alpha: 0.12),
                ),
              ),

              // 🔵 Bottom Glow
              Positioned(
                bottom: -constraints.maxHeight * 0.15,
                right: -constraints.maxWidth * 0.2,
                child: _Glow(
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

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
