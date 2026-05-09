import 'package:flutter/material.dart';

class PalmMerchantMatchScreen extends StatelessWidget {
  const PalmMerchantMatchScreen({
    super.key,
    required this.displayName,
    required this.walletBalance,
    required this.confidence,
    required this.amountCharged,
    this.profileUrl,
    this.transactionId,
    this.handIdMasked,
  });

  final String displayName;
  final double walletBalance;
  final double confidence;
  final double amountCharged;
  final String? profileUrl;
  final String? transactionId;
  /// Masked palm enrollment hand ID (from [PalmHandIdService.maskHandId]).
  final String? handIdMasked;

  static String _initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Charge complete'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFF3A86FF).withValues(alpha: 0.15),
                backgroundImage:
                    profileUrl != null && profileUrl!.isNotEmpty ? NetworkImage(profileUrl!) : null,
                child: profileUrl == null || profileUrl!.isEmpty
                    ? Text(
                        _initials(displayName),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Match similarity • ${confidence.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              _tile(
                'Amount charged',
                'PKR ${amountCharged.toStringAsFixed(2)}',
              ),
              _tile(
                'Remaining wallet balance',
                'PKR ${walletBalance.toStringAsFixed(2)}',
              ),
              if (handIdMasked != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Hand ID • $handIdMasked',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.black45),
                  ),
                ),
              if (transactionId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Txn • $transactionId',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.black45),
                  ),
                ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFF3A86FF),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
