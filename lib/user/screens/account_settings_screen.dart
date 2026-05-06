import 'package:flutter/material.dart';
import 'package:paypalm/screens/auth_choice_screen.dart';
import 'package:paypalm/services/auth_service.dart';
import 'package:paypalm/services/local_app_state_service.dart';

import 'package:paypalm/user/widgets/account/menu_item.dart';
import 'package:paypalm/user/widgets/home/bottom_nav.dart';
import 'package:paypalm/widgets/custom_snackbar.dart';
import 'my_account_details_screen.dart';
import 'package:paypalm/user/widgets/account/account_selector.dart';
import 'package:paypalm/user/widgets/account/section_group.dart';
import 'transaction_history_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final LocalAppStateService _localState = LocalAppStateService();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _localState.ensureDefaults();
    final notifications = await _localState.getNotificationsEnabled();
    if (!mounted) return;
    setState(() => _notificationsEnabled = notifications);
  }

  Future<void> _toggleNotifications(bool value) async {
    await _localState.setNotificationsEnabled(value);
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
    CustomSnackbar.show(
      context: context,
      message: value ? 'Notifications enabled' : 'Notifications disabled',
      type: SnackbarType.info,
    );
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(text: await _localState.getName());
    final phone = TextEditingController(text: await _localState.getPhone());
    final email = TextEditingController(text: await _localState.getEmail());

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty ||
                    phone.text.trim().isEmpty ||
                    email.text.trim().isEmpty) {
                  return;
                }
                await _localState.updateProfile(
                  name: name.text,
                  phone: phone.text,
                  email: email.text,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    CustomSnackbar.show(
      context: context,
      message: 'Profile updated successfully',
      type: SnackbarType.success,
    );
    setState(() {});
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
      (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScreenTitle(),
                const SizedBox(height: 32),
                _buildHeaderLabel('ACCOUNT'),
                const SizedBox(height: 16),
                const AccountSelector(),
                const SizedBox(height: 16),
                AccountSectionGroup(children: [
                  AccountMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    onTap: _editProfile,
                  ),
                  AccountMenuItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Transaction History',
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const TransactionHistoryScreen(),
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
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 600),
                        ),
                      );
                    },
                  ),
                  _buildLinkCardItem(context),
                  AccountMenuItem(
                    icon: _notificationsEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    title: _notificationsEnabled
                        ? 'Disable Notifications'
                        : 'Enable Notifications',
                    onTap: () => _toggleNotifications(!_notificationsEnabled),
                  ),
                  AccountMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: _logout,
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(activeIndex: 1),
      floatingActionButton: const CenterQRButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildScreenTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        Text(
          'Account info, Settings & More',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildHeaderLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildLinkCardItem(BuildContext context) {
    return AccountMenuItem(
      icon: Icons.credit_card_rounded,
      title: 'Link Debit Card',
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MyAccountDetailsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      },
    );
  }
}
