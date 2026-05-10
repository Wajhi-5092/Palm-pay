import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:paypalm/services/auth_service.dart';
import 'package:paypalm/services/merchant_service.dart';
import 'package:paypalm/models/merchant_model.dart';
import '../widgets/merchant_balance_card.dart';
import '../widgets/merchant_action_card.dart';
import '../widgets/merchant_transaction_list.dart';
import 'merchant_sales_screen.dart';
import 'merchant_history_screen.dart';
import 'merchant_settings_screen.dart';
import 'merchant_withdrawal_screen.dart';
import 'package:paypalm/screens/auth_choice_screen.dart';
import 'package:paypalm/merchant/screens/merchant_billing_screen.dart';

class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  int _selectedIndex = 0;
  Merchant? _merchant;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  StreamSubscription<Merchant?>? _merchantLiveSub;

  final _merchantService = MerchantService();

  // Light Mode Palette
  static const Color bgGradientStart = Color(0xFFF8FAFC); // Very light slate
  static const Color accentBlue = Color(0xFF3A86FF);
  static const Color accentTeal = Color(0xFF00D1B2);
  static const Color textPrimary = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
    _merchantLiveSub =
        _merchantService.watchCurrentMerchant().listen((merchant) async {
      if (!mounted) return;
      setState(() => _merchant = merchant);
      if (merchant != null) {
        try {
          final s = await _merchantService.getMerchantStats(merchant.id);
          if (mounted) setState(() => _stats = s);
        } catch (_) {/* keep previous stats */}
      }
    });
  }

  @override
  void dispose() {
    _merchantLiveSub?.cancel();
    super.dispose();
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const MerchantSalesScreen();
      case 2:
        return const MerchantHistoryScreen();
      case 3:
        return const MerchantSettingsScreen();
      default:
        return _buildDashboard();
    }
  }

  Future<void> _loadMerchantData() async {
    try {
      _merchant = await _merchantService.getCurrentMerchant();
      if (_merchant != null) {
        _stats = await _merchantService.getMerchantStats(_merchant!.id);
      } else {
        // Merchant data not found - user may have been logged out
        if (mounted) {
          // Only redirect if explicitly needed
          print('Warning: Merchant data not found');
        }
      }
    } catch (e) {
      print('Error loading merchant data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                      _merchant?.storeName ?? 'Merchant Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${_merchant?.merchantId ?? ''}',
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Balance Card
                      _isLoading
                          ? const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : MerchantBalanceCard(
                              balance: _merchant?.walletBalance ?? 0.0,
                              todayEarnings: _stats?['todaySales'] ?? 0.0,
                              weeklyEarnings: _stats?['weeklySales'] ?? 0.0,
                            ),

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
                          Expanded(
                            child: MerchantActionCard(
                              icon: Icons.pan_tool_rounded,
                              title: 'Receive',
                              color: accentTeal,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MerchantBillingScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MerchantActionCard(
                              icon: Icons.account_balance_rounded,
                              title: 'Withdraw',
                              color: accentBlue,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const MerchantWithdrawalScreen()),
                                );
                              },
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

                      _isLoading
                          ? const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()))
                          : _merchant == null
                              ? const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Text(
                                      'Unable to load merchant data',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              : MerchantTransactionList(
                                  transactionsStream: _merchantService
                                      .getMerchantTransactions(_merchant!.id),
                                ),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glowSize =
        (MediaQuery.of(context).size.shortestSide * 0.7).clamp(190.0, 320.0);

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
            child: _LightAmbientGlow(
              color: accentBlue.withValues(alpha: 0.08),
              size: glowSize,
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _LightAmbientGlow(
              color: accentTeal.withValues(alpha: 0.08),
              size: glowSize,
            ),
          ),

          // Render active screen wrapper in SafeArea context
          _getSelectedPage(),
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
      onSelected: (value) async {
        if (value == 'switch') {
          // Switch to personal account logic
        } else if (value == 'logout') {
          // Make logout feel instant: navigate away first, then clean up in background.
          if (!mounted) return;
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

          unawaited(AuthService().logout(clearMpin: false));
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
  final double size;
  const _LightAmbientGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
