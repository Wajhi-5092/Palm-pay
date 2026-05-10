import 'package:flutter/material.dart';
import 'package:paypalm/user/screens/account_settings_screen.dart';
import 'package:paypalm/user/screens/home_page.dart';

class BottomNav extends StatelessWidget {
  final int activeIndex;
  const BottomNav({super.key, this.activeIndex = 0});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navHeight = (screenWidth * 0.18).clamp(64.0, 74.0);
    (screenWidth * 0.16).clamp(44.0, 72.0);
    final iconSize = (screenWidth * 0.067).clamp(22.0, 28.0);
    final labelSize = (screenWidth * 0.027).clamp(9.0, 11.0);

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      color: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: navHeight,
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
                iconSize: iconSize,
                labelSize: labelSize,
                isActive: activeIndex == 0,
                onTap: () {
                  if (activeIndex != 0) {
                    Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const HomePage(),
                    ));
                  }
                },
              ),
              _buildNavItem(
                context,
                Icons.person_rounded,
                'Account',
                iconSize: iconSize,
                labelSize: labelSize,
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
    required double iconSize,
    required double labelSize,
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
          Icon(
            icon,
            color: isActive ? activeColor : inactiveColor,
            size: iconSize,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : inactiveColor,
              fontSize: labelSize,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = (screenWidth * 0.18).clamp(58.0, 72.0);
    final iconSize = (buttonSize * 0.46).clamp(26.0, 34.0);
    final borderWidth = (buttonSize * 0.06).clamp(3.0, 4.5);

    return Container(
      width: buttonSize,
      height: buttonSize,
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
        border: Border.all(color: const Color(0xFFF1F3F5), width: borderWidth),
      ),
      child: Center(
        child: Icon(
          Icons.pan_tool_rounded,
          color: Colors.white,
          size: iconSize,
          shadows: [
            Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}
