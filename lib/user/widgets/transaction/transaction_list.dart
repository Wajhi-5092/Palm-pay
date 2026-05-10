import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paypalm/models/transaction_model.dart';
import 'package:paypalm/services/user_transaction_firestore_service.dart';

/// Live palm / wallet activity for the signed-in personal user (`transactions`).
class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  /// Short hash of Firebase merchant uid for legacy rows missing [Transaction.merchantCode].
  static String _shortMerchantRef(String firebaseUid) {
    if (firebaseUid.length <= 12) return firebaseUid;
    return '${firebaseUid.substring(0, 6)}…${firebaseUid.substring(firebaseUid.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    const Color textPrimary = Color(0xFF1E293B);
    const Color outgoing = Color(0xFFE11D48);
    final timeFmt = DateFormat('d MMM, y • h:mm a');

    return StreamBuilder<List<Transaction>>(
      stream: UserTransactionFirestoreService.watchCurrentUserTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load activity: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final txs = snapshot.data ?? [];
        if (txs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No payments yet',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: txs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final t = txs[index];
            final dateStr = timeFmt.format(t.createdAt);
            final amount = t.netAmount;
            final store = t.merchantName?.trim();
            final code = t.merchantCode?.trim();
            final subtitleName = store != null && store.isNotEmpty
                ? store
                : 'Merchant';
            final idLine = (code != null && code.isNotEmpty)
                ? 'ID: $code'
                : (t.merchantId.isNotEmpty
                    ? 'Ref: ${_shortMerchantRef(t.merchantId)}'
                    : null);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: outgoing.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: outgoing,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paid to merchant',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0.4,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitleName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: textPrimary,
                              ),
                            ),
                            if (idLine != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                idLine,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (t.merchantOwnerName != null &&
                                t.merchantOwnerName!.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Contact: ${t.merchantOwnerName!.trim()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              children: [
                                if (t.merchantCategory != null &&
                                    t.merchantCategory!.trim().isNotEmpty)
                                  _chip(
                                    Icons.category_outlined,
                                    t.merchantCategory!.trim(),
                                  ),
                                if (t.merchantCity != null &&
                                    t.merchantCity!.trim().isNotEmpty)
                                  _chip(
                                    Icons.place_outlined,
                                    t.merchantCity!.trim(),
                                  ),
                                if (t.merchantPhone != null &&
                                    t.merchantPhone!.trim().isNotEmpty)
                                  _chip(
                                    Icons.phone_outlined,
                                    t.merchantPhone!.trim(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '-Rs ${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: outgoing,
                            ),
                          ),
                          Text(
                            t.status == TransactionStatus.completed
                                ? 'Paid'
                                : t.status.name,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          t.description?.trim().isNotEmpty == true
                              ? t.description!.trim()
                              : (t.paymentLabel.isNotEmpty
                                  ? t.paymentLabel
                                  : 'Palm checkout'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

extension on Transaction {
  String get paymentLabel {
    final pm = paymentMethod?.toLowerCase() ?? '';
    if (pm.contains('palm')) return 'Palm payment';
    if (pm.isNotEmpty) return pm.replaceAll('_', ' ');
    return '';
  }
}
