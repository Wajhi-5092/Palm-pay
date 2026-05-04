import 'package:flutter/material.dart';
import 'package:paypalm/user/widgets/account/menu_item.dart';
import 'package:paypalm/user/widgets/account/profile_section.dart';
import 'favourites_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Account',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: ProfileSection(),
              ),

              const SizedBox(height: 10),

              // 2. Menu Items Grouped with 3D Look
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // GROUP 1: Account Actions
                    _build3DGroup([
                      AccountMenuItem(
                        icon: Icons.favorite_border_rounded,
                        title: 'My Favourites',
                        onTap: () =>
                            _navigateTo(context, const FavouritesScreen()),
                      ),
                      const AccountMenuItem(
                        icon: Icons.person_rounded,
                        title: 'Identity Verification',
                      ),
                      const AccountMenuItem(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'My Approvals',
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // GROUP 2: Security & Settings
                    _build3DGroup([
                      const AccountMenuItem(
                        icon: Icons.security_rounded,
                        title: 'Security Settings',
                      ),
                      const AccountMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification Settings',
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Logout Action
                    _build3DGroup([
                      const AccountMenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        isDestructive: true,
                      ),
                    ]),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Widget _build3DGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }
}
