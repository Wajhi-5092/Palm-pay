import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:paypalm/palm/data/palm_customer_match.dart';
import 'package:paypalm/palm/data/palm_simple_firestore_service.dart';
import 'package:paypalm/palm/services/palm_hand_id_service.dart';
import 'package:paypalm/palm/ui/palm_merchant_match_screen.dart';

/// Shown after a merchant palm scan resolves to a registered customer — confirm details before charging.
class PalmMerchantCustomerConfirmScreen extends StatefulWidget {
  const PalmMerchantCustomerConfirmScreen({
    super.key,
    required this.match,
    required this.amount,
    required this.embedding,
  });

  final PalmCustomerMatch match;
  final double amount;
  final Float32List embedding;

  @override
  State<PalmMerchantCustomerConfirmScreen> createState() =>
      _PalmMerchantCustomerConfirmScreenState();
}

class _PalmMerchantCustomerConfirmScreenState
    extends State<PalmMerchantCustomerConfirmScreen> {
  bool _busy = false;

  Future<void> _confirmCharge() async {
    setState(() => _busy = true);
    try {
      final tid = await PalmSimpleFirestoreService.saveMerchantDemoScan(
        amount: widget.amount,
        embedding: widget.embedding,
        customerUid: widget.match.uid,
        customerDisplayName: widget.match.displayName,
        matchSimilarity: widget.match.similarity,
        customerHandId: widget.match.handId,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PalmMerchantMatchScreen(
            displayName: widget.match.displayName,
            walletBalance: 0,
            confidence: widget.match.confidencePercent,
            amountCharged: widget.amount,
            profileUrl: widget.match.photoUrl,
            transactionId: tid,
            handIdMasked: widget.match.handId != null
                ? PalmHandIdService.maskHandId(widget.match.handId!)
                : null,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Confirm customer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Review before payment',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        const Color(0xFF3A86FF).withValues(alpha: 0.15),
                    backgroundImage: m.photoUrl != null &&
                            m.photoUrl!.isNotEmpty
                        ? NetworkImage(m.photoUrl!)
                        : null,
                    child: m.photoUrl == null || m.photoUrl!.isEmpty
                        ? Text(
                            _initials(m.displayName),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.displayName,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Match ${m.confidencePercent.toStringAsFixed(1)}%',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (m.phone != null && m.phone!.trim().isNotEmpty)
                _row(context, 'Phone', m.phone!.trim()),
              if (m.email != null && m.email!.trim().isNotEmpty)
                _row(context, 'Email', m.email!.trim()),
              if (m.handId != null && m.handId!.trim().isNotEmpty)
                _row(
                  context,
                  'Hand ID',
                  PalmHandIdService.maskHandId(m.handId!),
                ),
              _row(
                context,
                'Amount to charge',
                'PKR ${widget.amount.toStringAsFixed(2)}',
                emphasize: true,
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _confirmCharge,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFF3A86FF),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Charge customer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
                fontWeight: emphasize ? FontWeight.w600 : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
                fontSize: emphasize ? 18 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
