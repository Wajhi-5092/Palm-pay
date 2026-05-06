import 'dart:ui';
import 'package:flutter/material.dart';
import '../user/screens/login_screen.dart';
import '../merchant/screens/merchant_home_screen.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    final glowSize = (size.shortestSide * 0.7).clamp(200.0, 320.0);

    // Responsive scaling
    final isSmall = height < 700;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),

          // Ambient Glow
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: glowSize,
              height: glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3A86FF).withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: height),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.07),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * 0.06),

                      // Branding
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'PAYPALM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmall ? 20 : 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'SECURE BIOMETRIC PAYMENTS',
                                style: TextStyle(
                                  color: const Color(0xFF00D1B2),
                                  fontSize: isSmall ? 9 : 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: height * 0.1),

                      // Heading
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isSmall ? 16 : 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose your portal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 24 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: height * 0.05),

                      // Cards
                      RoleCard(
                        title: 'Personal Account',
                        subtitle: 'Scan your palm to pay instantly',
                        icon: Icons.fingerprint_rounded,
                        color: const Color(0xFF00D1B2),
                        isSmall: isSmall,
                        onPressed: () => _navigate(
                          context,
                          const LoginScreen(),
                        ),
                      ),

                      SizedBox(height: height * 0.025),

                      RoleCard(
                        title: 'Merchant Hub',
                        subtitle: 'Manage sales and palm terminals',
                        icon: Icons.storefront_rounded,
                        color: const Color(0xFF3A86FF),
                        isSmall: isSmall,
                        onPressed: () => _navigate(
                          context,
                          const MerchantHomeScreen(),
                        ),
                      ),

                      SizedBox(height: height * 0.08),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.isSmall,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(isSmall ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmall ? 10 : 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isSmall ? 24 : 28,
                  ),
                ),
                SizedBox(width: isSmall ? 14 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 16 : 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: isSmall ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: isSmall ? 14 : 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
