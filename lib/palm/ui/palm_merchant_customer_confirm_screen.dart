import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:paypalm/palm/data/palm_api_exception.dart';
import 'package:paypalm/palm/data/palm_customer_match.dart';
import 'package:paypalm/palm/data/palm_firestore_payment_service.dart';
import 'package:paypalm/palm/data/palm_simple_firestore_service.dart';
import 'package:paypalm/palm/services/palm_hand_id_service.dart';
import 'package:paypalm/palm/ui/palm_merchant_match_screen.dart';

/// After palm match: review customer, then **one** Firestore transaction moves funds (no Cloud Function).
class PalmMerchantCustomerConfirmScreen extends StatefulWidget {
  const PalmMerchantCustomerConfirmScreen({
    super.key,
    required this.match,
    required this.amount,
    required this.embedding,
    this.checkoutSessionId,
  });

  final PalmCustomerMatch match;
  final double amount;
  final Float32List embedding;
  final String? checkoutSessionId;

  @override
  State<PalmMerchantCustomerConfirmScreen> createState() =>
      _PalmMerchantCustomerConfirmScreenState();
}

class _PalmMerchantCustomerConfirmScreenState
    extends State<PalmMerchantCustomerConfirmScreen> {
  bool _busy = false;

  /// Single Firestore transaction: deduct customer wallet, credit merchant, write tx record.
  Future<void> _confirmCharge() async {
    setState(() => _busy = true);
    try {
      final res = await PalmFirestorePaymentService.finalizePalmPaymentDirect(
        customerUid: widget.match.uid,
        amount: widget.amount,
        embedding: widget.embedding,
        handId: widget.match.handId,
        threshold: PalmSimpleFirestoreService.merchantMatchThreshold,
        checkoutSessionId: widget.checkoutSessionId,
      );
      if (res['success'] != true) {
        throw PalmApiException(
          code: 'unknown',
          message: res['message']?.toString() ?? 'Payment could not be completed.',
        );
      }
      final confidence =
          (res['confidence'] as num?)?.toDouble() ?? widget.match.confidencePercent;
      final tid = res['transactionId']?.toString();
      final merchantWb = (res['merchantWalletBalance'] as num?)?.toDouble();
      if (!mounted) return;
      final summary = res['message']?.toString().trim();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PalmMerchantMatchScreen(
            displayName:
                res['displayName']?.toString() ?? widget.match.displayName,
            confidence: confidence,
            amountCharged: widget.amount,
            profileUrl: widget.match.photoUrl,
            transactionId: tid,
            handIdMasked: widget.match.handId != null
                ? PalmHandIdService.maskHandId(widget.match.handId!)
                : null,
            merchantWalletBalance: merchantWb,
            successDetail:
                summary != null && summary.isNotEmpty ? summary : null,
          ),
        ),
      );
    } on PalmApiException catch (e) {
      if (mounted) _showPaymentFailed(_userFacingPaymentError(e));
    } on FirebaseException catch (e) {
      if (mounted) _showPaymentFailed(e.message ?? e.code);
    } catch (e) {
      if (mounted) _showPaymentFailed(_userFacingPaymentError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _userFacingPaymentError(Object e) {
    if (e is PalmApiException) {
      return e.message ?? 'Payment could not be completed.';
    }
    return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }

  Future<void> _showPaymentFailed(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.error_outline, color: Colors.red.shade700, size: 32),
        title: const Text('Payment failed'),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
        title: const Text('Pay'),
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
                'Customer verified — complete payment',
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
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Text(
                  "This amount is deducted from ${m.displayName}'s wallet and "
                  'credited to your merchant balance.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
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
                        'Pay now',
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
