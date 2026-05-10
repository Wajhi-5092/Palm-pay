import 'package:flutter/material.dart';
import 'package:paypalm/services/local_app_state_service.dart';
import 'package:paypalm/services/user_wallet_firestore_service.dart';
import 'package:paypalm/user/modules/add_cash/add_cash_demo_money_screen.dart';

class WalletCard extends StatefulWidget {
  const WalletCard({super.key});

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  bool _isBalanceVisible = true;

  String _formatBalance(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      final reverseIndex = whole.length - i;
      buffer.write(whole[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'Rs. ${buffer.toString()}.${parts[1]}';
  }

  Future<void> _openDemoMoneyPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddCashDemoMoneyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: UserWalletFirestoreService.watchWalletBalance(),
      builder: (context, snapshot) {
        final balance = snapshot.hasData
            ? snapshot.data!
            : LocalAppStateService.defaultBalance;

        return LayoutBuilder(
          builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmall = width < 350;

        return GestureDetector(
          onTap: () {},
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: width * 0.02,
              vertical: width * 0.06,
            ),
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment(0.7, -0.6),
                radius: 1.2,
                colors: [
                  Color.fromARGB(255, 106, 225, 189),
                  Color.fromARGB(255, 49, 109, 153),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 0,
                  spreadRadius: -0.5,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    bottom: -50,
                    child: Opacity(
                      opacity: 0.04,
                      child: Icon(
                        Icons.grid_on_rounded,
                        size: width * 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(width * 0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.03,
                                vertical: width * 0.02,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.payment,
                                      color: Colors.white,
                                      size: isSmall ? 14 : 16),
                                  SizedBox(width: width * 0.02),
                                  Text(
                                    'PayPalm Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmall ? 11 : 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: width * 0.07),

                        Text(
                          'Available Balance',
                          style: TextStyle(
                            color:
                                const Color(0xFFF5F5E9).withValues(alpha: 0.7),
                            fontSize: isSmall ? 11 : 13,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // 🔥 IMPORTANT FIX (no overflow)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                _isBalanceVisible
                                    ? _formatBalance(balance)
                                    : 'Rs. •••••••',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFFF5F5E9),
                                  fontSize: isSmall ? 24 : 32,
                                  fontWeight: FontWeight.w900,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: width * 0.03),
                            GestureDetector(
                              onTap: () => setState(
                                () => _isBalanceVisible = !_isBalanceVisible,
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(bottom: width * 0.02),
                                child: Icon(
                                  Icons.visibility,
                                  color: Colors.white70,
                                  size: isSmall ? 18 : 22,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: width * 0.05),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Tap to Hide Balance',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: isSmall ? 10 : 11,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _openDemoMoneyPage(context),
                              child: _buildPremiumButton('Add Cash', isSmall),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildPremiumButton(String label, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 14 : 18,
        vertical: isSmall ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5E9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF004D40),
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
