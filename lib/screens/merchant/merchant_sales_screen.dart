import 'package:flutter/material.dart';

class MerchantSalesScreen extends StatelessWidget {
  const MerchantSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color textPrimary = Color(0xFF1E293B);
    const Color accentBlue = Color(0xFF3A86FF);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // 1. Total Revenue Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Revenue (This Week)',
                        style: TextStyle(
                          color: textPrimary.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '+12.5%',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '\$4,892.50',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 2. Weekly Bar Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Trends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Mar 1 - Mar 7',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('Mon', 120, 200, accentBlue),
                  _buildBar('Tue', 160, 200, accentBlue),
                  _buildBar('Wed', 90, 200, accentBlue),
                  _buildBar('Thu', 180, 200, accentBlue),
                  _buildBar('Fri', 240, 280, const Color(0xFF00D1B2),
                      isHighlighted: true),
                  _buildBar('Sat', 150, 200, accentBlue),
                  _buildBar('Sun', 110, 200, accentBlue),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 3. Top Selling Items
            const Text(
              'Top Payment Sources',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSourceItem('Palm Scan Terminal 1', '68% of sales',
                Icons.fingerprint_rounded, '\$3,326.90'),
            _buildSourceItem('QR Code Online', '22% of sales',
                Icons.qr_code_scanner_rounded, '\$1,076.35'),
            _buildSourceItem('Manual Entry', '10% of sales',
                Icons.keyboard_rounded, '\$489.25'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, double height, double maxHeight, Color color,
      {bool isHighlighted = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isHighlighted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Peak',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        Container(
          width: 38,
          height: height * (200 / maxHeight) * 0.7, // scaled height
          decoration: BoxDecoration(
            color: color.withValues(alpha: isHighlighted ? 1.0 : 0.6),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: isHighlighted ? const Color(0xFF1E293B) : Colors.grey,
            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceItem(
      String title, String subtitle, IconData icon, String amount) {
    const Color textPrimary = Color(0xFF1E293B);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: textPrimary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: textPrimary.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15, color: textPrimary),
          ),
        ],
      ),
    );
  }
}
