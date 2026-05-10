import 'package:flutter/material.dart';

class PalmMerchantMatchScreen extends StatelessWidget {
  const PalmMerchantMatchScreen({
    super.key,
    required this.displayName,
    required this.confidence,
    required this.amountCharged,
    this.profileUrl,
    this.transactionId,
    this.handIdMasked,
    this.merchantWalletBalance,
    this.successDetail,
  });

  final String displayName;
  final double confidence;
  final double amountCharged;
  final String? profileUrl;
  final String? transactionId;
  /// Masked palm enrollment hand ID (from [PalmHandIdService.maskHandId]).
  final String? handIdMasked;
  /// Merchant store wallet after this charge (server-side), if provided.
  final double? merchantWalletBalance;

  /// Short confirmation from the server (e.g. amount transferred).
  final String? successDetail;

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
        title: const Text('Payment successful'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                successDetail ??
                    'Payment was taken from the customer\'s wallet and '
                    'credited to your store.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
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
              if (merchantWalletBalance != null)
                _tile(
                  'Your store balance',
                  'PKR ${merchantWalletBalance!.toStringAsFixed(2)}',
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
