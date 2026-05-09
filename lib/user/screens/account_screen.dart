import 'package:flutter/material.dart';
import 'package:paypalm/screens/auth_choice_screen.dart';
import 'package:paypalm/services/auth_service.dart';
import 'package:paypalm/user/modules/account/account_feature_placeholder_screen.dart';
import 'package:paypalm/user/modules/security/security_settings_screen.dart';
import 'package:paypalm/user/widgets/account/menu_item.dart';
import 'package:paypalm/user/widgets/account/profile_section.dart';
import 'package:paypalm/widgets/custom_snackbar.dart';
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
                      AccountMenuItem(
                        icon: Icons.person_rounded,
                        title: 'Identity Verification',
                        onTap: () => _navigateTo(
                          context,
                          const AccountFeaturePlaceholderScreen(
                            title: 'Identity Verification',
                            message:
                                'Identity verification module will be enabled in a future release.',
                          ),
                        ),
                      ),
                      AccountMenuItem(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'My Approvals',
                        onTap: () => _navigateTo(
                          context,
                          const AccountFeaturePlaceholderScreen(
                            title: 'My Approvals',
                            message:
                                'Approval tracking module will be available soon.',
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // GROUP 2: Security & Settings
                    _build3DGroup([
                      AccountMenuItem(
                        icon: Icons.security_rounded,
                        title: 'Security Settings',
                        onTap: () => _navigateTo(
                          context,
                          const SecuritySettingsScreen(),
                        ),
                      ),
                      AccountMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification Settings',
                        onTap: () => _navigateTo(
                          context,
                          const AccountFeaturePlaceholderScreen(
                            title: 'Notification Settings',
                            message:
                                'Notification settings are unchanged for now, as requested.',
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Delete account
                    _build3DGroup([
                      AccountMenuItem(
                        icon: Icons.delete_forever_rounded,
                        title: 'Delete account',
                        isDestructive: true,
                        onTap: () => _confirmDeleteAccount(context),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Logout Action
                    _build3DGroup([
                      AccountMenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        isDestructive: true,
                        onTap: () async {
                          await AuthService().logout();
                          if (!context.mounted) return;
                          CustomSnackbar.show(
                            context: context,
                            message: 'You are now logged out',
                            type: SnackbarType.info,
                          );
                          Navigator.of(context).pushAndRemoveUntil(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const AuthChoiceScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                            (route) => false,
                          );
                        },
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

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final passwordController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete account?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your profile will be removed and your email can be used for a new registration.',
                    style: Theme.of(dialogContext).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !context.mounted) return;

      try {
        await AuthService().deleteAccount(password: passwordController.text);
      } catch (e) {
        if (!context.mounted) return;
        CustomSnackbar.show(
          context: context,
          message: e.toString().replaceAll('Exception: ', ''),
          type: SnackbarType.error,
        );
        return;
      }

      if (!context.mounted) return;
      CustomSnackbar.show(
        context: context,
        message: 'Account deleted',
        type: SnackbarType.info,
      );
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthChoiceScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    } finally {
      passwordController.dispose();
    }
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
