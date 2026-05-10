import 'package:flutter/material.dart';
import 'package:paypalm/user/screens/palm_scan_screen.dart';
import 'package:paypalm/user/screens/transaction_history_screen.dart';
import 'package:paypalm/widgets/custom_snackbar.dart';
import 'package:paypalm/user/screens/account_screen.dart';

class MoreFeaturesGrid extends StatelessWidget {
  const MoreFeaturesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_FeatureItem> features = [
      _FeatureItem(
        title: 'Enroll Palm',
        icon: Icons.fingerprint_rounded,
        color: const Color(0xFF6AE1BD),
        onTap: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const PalmScanScreen(isRegistration: true),
            ),
          );
          if (!context.mounted) return;
          if (ok == true) {
            CustomSnackbar.show(
              context: context,
              message: 'Palm enrolled successfully.',
              type: SnackbarType.success,
            );
          }
        },
      ),
      _FeatureItem(
        title: 'History',
        icon: Icons.history_rounded,
        color: const Color(0xFF316D99),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionHistoryScreen(),
            ),
          );
        },
      ),
      _FeatureItem(
        title: 'Profile',
        icon: Icons.person_rounded,
        color: const Color(0xFF004D40),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountScreen(),
            ),
          );
        },
      ),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final feature = features[index];
            return GestureDetector(
              onTap: feature.onTap,
              child: Column(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: feature.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: feature.color.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      feature.icon,
                      color: feature.color.withValues(alpha: 0.9),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: features.length,
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _FeatureItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
