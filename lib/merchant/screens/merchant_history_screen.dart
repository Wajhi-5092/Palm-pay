import 'package:flutter/material.dart';
import 'package:paypalm/services/merchant_service.dart';
import 'package:paypalm/models/merchant_model.dart';
import '../widgets/merchant_transaction_list.dart';

class MerchantHistoryScreen extends StatefulWidget {
  const MerchantHistoryScreen({super.key});

  @override
  State<MerchantHistoryScreen> createState() => _MerchantHistoryScreenState();
}

class _MerchantHistoryScreenState extends State<MerchantHistoryScreen> {
  Merchant? _merchant;
  final _merchantService = MerchantService();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMerchant();
  }

  Future<void> _loadMerchant() async {
    try {
      _merchant = await _merchantService.getCurrentMerchant();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color textPrimary = Color(0xFF1E293B);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildFilterChip('All', true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('Income', false),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('Outcome', false),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _merchant == null
                      ? const Center(child: Text('Merchant data not found'))
                      : MerchantTransactionList(
                          transactionsStream: _merchantService
                              .getMerchantTransactions(_merchant!.id),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    const Color accentBlue = Color(0xFF3A86FF);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? accentBlue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? accentBlue : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
