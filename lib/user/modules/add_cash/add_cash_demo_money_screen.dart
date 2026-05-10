import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paypalm/services/user_wallet_firestore_service.dart';
import 'package:paypalm/widgets/custom_snackbar.dart';

class AddCashDemoMoneyScreen extends StatefulWidget {
  const AddCashDemoMoneyScreen({super.key});

  @override
  State<AddCashDemoMoneyScreen> createState() => _AddCashDemoMoneyScreenState();
}

class _AddCashDemoMoneyScreenState extends State<AddCashDemoMoneyScreen> {
  static const double _maxInputAmount = 100000;
  final TextEditingController _amountController = TextEditingController();
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    if (FirebaseAuth.instance.currentUser == null) {
      if (mounted) setState(() => _balance = 0);
      return;
    }
    final v = await UserWalletFirestoreService.getWalletBalanceOnce();
    if (mounted) setState(() => _balance = v);
  }

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

  Future<void> _addCustomAmount() async {
    final input = _amountController.text.trim();
    final amount = double.tryParse(input);
    if (amount == null || amount <= 0) {
      CustomSnackbar.show(
        context: context,
        message: 'Enter a valid amount',
        type: SnackbarType.warning,
      );
      return;
    }
    if (amount > _maxInputAmount) {
      CustomSnackbar.show(
        context: context,
        message: 'Maximum allowed amount is Rs. 100000',
        type: SnackbarType.warning,
      );
      return;
    }

    final updated = await UserWalletFirestoreService.incrementWallet(amount);
    if (!mounted) return;
    _amountController.clear();
    setState(() => _balance = updated);
    CustomSnackbar.show(
      context: context,
      message: 'Added ${_formatBalance(amount)} to demo wallet',
      type: SnackbarType.success,
    );
  }

  Future<void> _clearAllDemoMoney() async {
    await UserWalletFirestoreService.setWalletBalance(0);
    if (!mounted) return;
    setState(() => _balance = 0);
    CustomSnackbar.show(
      context: context,
      message: 'All demo money cleared',
      type: SnackbarType.info,
    );
  }

  Future<void> _resetDemoMoney() async {
    await UserWalletFirestoreService.setWalletBalance(50000);
    if (!mounted) return;
    setState(() => _balance = 50000);
    CustomSnackbar.show(
      context: context,
      message: 'Demo wallet reset to Rs. 50000',
      type: SnackbarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Cash - Demo Money')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Demo Balance',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatBalance(_balance),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Custom Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can add any amount up to Rs. 100000 at a time.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter amount (max 100000)',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _addCustomAmount,
                  child: const Text('Add Demo Money'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearAllDemoMoney,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetDemoMoney,
                      child: const Text('Reset to 50000'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
