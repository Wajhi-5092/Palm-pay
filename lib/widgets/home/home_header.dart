import 'package:flutter/material.dart';
import '../../screens/user/account_screen.dart';
import '../../screens/auth_choice_screen.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // 1. More complex gradient for depth
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FAF6), Color.fromARGB(255, 98, 145, 202)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // 2. Shadows to "lift" the header
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          // Inner light highlight for 3D effect
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 0,
            offset: const Offset(0, 1),
            spreadRadius: -0.5,
          ),
        ],
        // 3. Subtle rounding for a modern feel
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 1. Left Section: Fixed width to match the right side
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const AccountScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOutCubic;
                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: FadeTransition(
                                opacity: animation, child: child),
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 600),
                      ),
                    );
                  },
                  child: _buildAvatar(),
                ),
              ),
            ),

            // 2. Center Section: Branding
            Expanded(
              flex: 2, // Gives the center more room to breathe
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: const Color.fromARGB(255, 0, 40, 104),
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  Text(
                    'DIGITAL BANK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: const Color.fromARGB(255, 0, 42, 104),
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Right Section: Actions
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildIconButton(
                    Icons.notifications_none,
                    Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    Icons.logout,
                    const Color.fromARGB(255, 108, 9, 9),
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const AuthChoiceScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.person,
          color: Color.fromARGB(255, 0, 54, 104),
          size: 18,
        ),
      ),
    );
  }
}
