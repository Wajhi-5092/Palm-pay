import 'package:flutter/material.dart';

class MerchantSettingsScreen extends StatelessWidget {
  const MerchantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color textPrimary = Color(0xFF1E293B);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Overview Card
                  _buildProfileHeader(context),
                  const SizedBox(height: 32),

                  // Section: Business
                  _buildSectionHeader('Business Management'),
                  _buildSettingsItem(
                    icon: Icons.storefront_rounded,
                    title: 'Business Profile',
                    subtitle: 'Manage store details, tax ID, and hours',
                    iconColor: const Color(0xFF3A86FF),
                  ),
                  _buildSettingsItem(
                    icon: Icons.fingerprint_rounded,
                    title: 'Palm Terminals',
                    subtitle: 'Add, update or remove scanning devices',
                    iconColor: const Color(0xFF00D1B2),
                  ),
                  _buildSettingsItem(
                    icon: Icons.group_add_rounded,
                    title: 'Staff Accounts',
                    subtitle: 'Manage employees and permissions',
                    iconColor: const Color(0xFF8B5CF6),
                  ),

                  const SizedBox(height: 24),

                  // Section: Financial
                  _buildSectionHeader('Financial & Payments'),
                  _buildSettingsItem(
                    icon: Icons.account_balance_rounded,
                    title: 'Bank Accounts',
                    subtitle: 'Manage automatic withdrawal routing',
                    iconColor: const Color(0xFFF59E0B),
                  ),
                  _buildSettingsItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Taxes & Invoicing',
                    subtitle: 'Configure automated receipt creation',
                    iconColor: const Color(0xFFEC4899),
                  ),

                  const SizedBox(height: 24),

                  // Section: App Settings
                  _buildSectionHeader('App & Security'),
                  _buildSettingsItem(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notifications',
                    subtitle: 'Alerts for payments and transfers',
                    iconColor: const Color(0xFF3A86FF),
                    trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeThumbColor: const Color(0xFF3A86FF),
                    ),
                  ),
                  _buildSettingsItem(
                    icon: Icons.security_rounded,
                    title: 'Security & Biometrics',
                    subtitle: 'App PIN, lock timeout and 2FA',
                    iconColor: const Color(0xFF64748B),
                  ),

                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigation to auth screen or logout logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        foregroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    const Color textPrimary = Color(0xFF1E293B);
    const Color accentBlue = Color(0xFF3A86FF);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: accentBlue.withValues(alpha: 0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: accentBlue.withValues(alpha: 0.1),
              child: const Icon(Icons.store_mall_directory_rounded,
                  color: accentBlue, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fresh Market LLC',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: #88291 • Verified',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00D1B2),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            color: textPrimary.withValues(alpha: 0.4),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    Widget? trailing,
  }) {
    const Color textPrimary = Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
                    color: textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textPrimary.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else
            Icon(
              Icons.chevron_right_rounded,
              color: textPrimary.withValues(alpha: 0.3),
              size: 24,
            ),
        ],
      ),
    );
  }
}
