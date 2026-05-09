import 'package:flutter/material.dart';

class MerchantBalanceCard extends StatelessWidget {
  final double balance;
  final double todayEarnings;
  final double weeklyEarnings;

  const MerchantBalanceCard({
    super.key,
    required this.balance,
    required this.todayEarnings,
    required this.weeklyEarnings,
  });

  @override
  Widget build(BuildContext context) {
    // Premium Blue Gradient Colors
    const Color gradStart = Color(0xFF3A86FF);
    const Color gradEnd = Color(0xFF002A68);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradStart, gradEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: gradEnd.withValues(alpha: 0.3),
            blurRadius: 25,
            spreadRadius: -5,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle background decorative circle for "glass" depth
          Positioned(
            right: -40,
            top: -40,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Rs ${balance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 30),

              // Stats Container with subtle divider
              Container(
                padding: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildStatItem('Today',
                            '+Rs ${todayEarnings.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}')),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                        child: _buildStatItem('This Week',
                            '+Rs ${weeklyEarnings.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
