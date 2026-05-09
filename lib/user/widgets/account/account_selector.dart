import 'package:flutter/material.dart';
import 'package:paypalm/services/local_app_state_service.dart';
import 'package:paypalm/widgets/custom_snackbar.dart';

class AccountSelector extends StatefulWidget {
  const AccountSelector({super.key});

  @override
  State<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends State<AccountSelector> {
  final LocalAppStateService _localState = LocalAppStateService();
  String _name = 'PayPalm User';
  String _phone = '0318 3116227';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _localState.ensureDefaults();
    final name = await _localState.getName();
    final phone = await _localState.getPhone();
    if (!mounted) return;
    setState(() {
      _name = name;
      _phone = phone;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color.fromARGB(255, 0, 57, 104);

    return GestureDetector(
      onTap: () => _showSwitchAccountSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // 1. Double Shadow for 3D "Elevated" Look
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 0,
              offset: Offset(0, -2), // Top highlight edge
            ),
          ],
        ),
        child: Row(
          children: [
            // 2. Icon Well (Depth effect)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: const Center(
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: primaryBlue,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    _phone,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // 3. 3D "Pressed" Arrow Button
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white,
                    offset: const Offset(-2, -2),
                    blurRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(2, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: primaryBlue,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSwitchAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95), // Glassy feel
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 4. Modern Handlebar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Switch Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  _build3DCloseButton(context),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Active Account (Selected Look)
              _buildAccountTile(
                title: _name,
                subtitle: _phone,
                icon: Icons.account_balance_wallet_rounded,
                isSelected: true,
              ),

              const SizedBox(height: 16),

              // 6. Add Account Tile
              _buildAccountTile(
                title: 'Add New Account',
                subtitle: 'Connect another wallet',
                icon: Icons.add_rounded,
                isSelected: false,
                isAction: true,
                onTap: () {
                  Navigator.pop(context);
                  CustomSnackbar.show(
                    context: context,
                    message: 'Multi-account support is coming soon',
                    type: SnackbarType.info,
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    bool isAction = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 0, 95, 142)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      0,
                      95,
                      142,
                    ).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAction
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isAction ? Colors.green : Colors.black87,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color.fromARGB(255, 0, 95, 142),
                size: 26,
              ),
          ],
        ),
      ),
    );
  }

  Widget _build3DCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.close_rounded, size: 18, color: Colors.black54),
      ),
    );
  }
}
