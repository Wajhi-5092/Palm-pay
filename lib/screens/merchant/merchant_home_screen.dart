import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/merchant/merchant_balance_card.dart';
import '../../widgets/merchant/merchant_action_card.dart';
import '../../widgets/merchant/merchant_transaction_list.dart';
import 'merchant_sales_screen.dart';
import 'merchant_history_screen.dart';
import 'merchant_settings_screen.dart';
import '../auth_choice_screen.dart';

class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  int _selectedIndex = 0;

  // Light Mode Palette
  static const Color bgGradientStart = Color(0xFFF8FAFC); // Very light slate
  static const Color accentBlue = Color(0xFF3A86FF);
  static const Color accentTeal = Color(0xFF00D1B2);
  static const Color textPrimary = Color(0xFF1E293B);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildDashboard(),
      const MerchantSalesScreen(),
      const MerchantHistoryScreen(),
      const MerchantSettingsScreen(),
    ];
  }

  Widget _buildDashboard() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merchant Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Store ID: #88291',
                      style: TextStyle(
                        color: textPrimary.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                _buildProfileAvatar(accentBlue),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  const MerchantBalanceCard(),

                  const SizedBox(height: 32),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Row
                  Row(
                    children: [
                      const Expanded(
                        child: MerchantActionCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'Receive',
                          color: accentTeal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MerchantActionCard(
                          icon: Icons.account_balance_rounded,
                          title: 'Withdraw',
                          color: accentBlue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Transactions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: accentBlue,
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        child: const Text('See All'),
                      ),
                    ],
                  ),

                  const MerchantTransactionList(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Soft Mesh Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgGradientStart, Colors.white],
              ),
            ),
          ),
          // Subtle accent "blobs" for depth
          Positioned(
            top: -50,
            right: -30,
            child: _LightAmbientGlow(color: accentBlue.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _LightAmbientGlow(color: accentTeal.withValues(alpha: 0.08)),
          ),

          // Render active screen wrapper in SafeArea context
          _pages[_selectedIndex],
        ],
      ),

      // Modern Light Bottom Nav
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: accentBlue,
          unselectedItemColor: textPrimary.withValues(alpha: 0.3),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded), label: 'Sales'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(Color accentColor) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'switch') {
          // Switch to personal account logic
        } else if (value == 'logout') {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const AuthChoiceScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (route) => false,
          );
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 50),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'switch',
          child: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 20),
              SizedBox(width: 12),
              Text('To Personal Account',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'notifications',
          child: Row(
            children: [
              Icon(Icons.notifications_active_rounded, size: 20),
              SizedBox(width: 12),
              Text('Notifications',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
              SizedBox(width: 12),
              Text('Log Out',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: accentColor.withValues(alpha: 0.1), width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: accentColor.withValues(alpha: 0.1),
              child: Icon(Icons.person_rounded, color: accentColor, size: 22),
            ),
          ),
          Positioned(
            top: 2,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper for the background effect
class _LightAmbientGlow extends StatelessWidget {
  final Color color;
  const _LightAmbientGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
