import 'package:flutter/material.dart';
import '../../screens/user/account_settings_screen.dart';

class BottomNav extends StatelessWidget {
  final int activeIndex;
  const BottomNav({super.key, this.activeIndex = 0});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      color: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
          border: Border(
            top: BorderSide(
              color: Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                Icons.home_rounded,
                'Home',
                isActive: activeIndex == 0,
                onTap: () {
                  if (activeIndex != 0) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
              const SizedBox(width: 60),
              _buildNavItem(
                context,
                Icons.person_rounded,
                'Account',
                isActive: activeIndex == 1,
                onTap: () {
                  if (activeIndex != 1) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const AccountSettingsScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              const begin = Offset(0.0, 1.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOutCubic;
                              var tween = Tween(
                                begin: begin,
                                end: end,
                              ).chain(CurveTween(curve: curve));
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 800),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    final Color activeColor = const Color.fromARGB(255, 0, 57, 104);
    final Color inactiveColor = Colors.grey.shade400;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? activeColor : inactiveColor, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : inactiveColor,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CenterQRButton extends StatelessWidget {
  const CenterQRButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.3),
          colors: [
            Color.fromARGB(255, 0, 95, 142),
            Color.fromARGB(255, 0, 95, 142),
            Color.fromARGB(255, 0, 95, 142),
          ],
        ),
        border: Border.all(color: const Color(0xFFF1F3F5), width: 4),
      ),
      child: const Center(
        child: Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 32,
          shadows: [
            Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}
