import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';

class MerchantTransactionList extends StatelessWidget {
  final Stream<List<Transaction>> transactionsStream;

  const MerchantTransactionList({
    super.key,
    required this.transactionsStream,
  });

  @override
  Widget build(BuildContext context) {
    const Color textPrimary = Color(0xFF1E293B);
    const Color successGreen = Color(0xFF10B981);

    return StreamBuilder<List<Transaction>>(
      stream: transactionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No transactions yet'),
            ),
          );
        }

        return Column(
          children: transactions.take(5).map((transaction) {
            final isWithdrawal = transaction.type == TransactionType.withdrawal;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFF1F5F9),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: textPrimary.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isWithdrawal
                          ? Colors.orange.withValues(alpha: 0.1)
                          : successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isWithdrawal
                          ? Icons.outbox_rounded
                          : Icons.add_to_photos_rounded,
                      color: isWithdrawal ? Colors.orange : successGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description ??
                              (isWithdrawal ? 'Withdrawal' : 'Sale'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}',
                          style: TextStyle(
                            color: textPrimary.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isWithdrawal ? '-' : '+'}Rs ${transaction.netAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isWithdrawal ? Colors.orange : successGreen,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        transaction.status == TransactionStatus.completed
                            ? 'Completed'
                            : 'Pending',
                        style: TextStyle(
                          color:
                              transaction.status == TransactionStatus.completed
                                  ? successGreen.withValues(alpha: 0.7)
                                  : Colors.orange.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
