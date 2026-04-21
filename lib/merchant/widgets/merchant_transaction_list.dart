import 'package:flutter/material.dart';

class MerchantTransactionList extends StatelessWidget {
  const MerchantTransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    const Color textPrimary = Color(0xFF1E293B);
    const Color successGreen = Color(0xFF10B981); // Softer Emerald

    return Column(
      children: List.generate(5, (index) {
        // Alternating data for a realistic look
        final bool isWithdrawal = index == 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF1F5F9), // Very light border
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
              // 1. Dynamic Icon Container
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
              const SizedBox(width: 16),

              // 2. Transaction Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWithdrawal
                          ? 'Withdraw to Bank'
                          : 'Palm Payment Received',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateTime.now().hour}:${DateTime.now().minute} • ID: #PAY-${index}902',
                      style: TextStyle(
                        color: textPrimary.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Amount Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isWithdrawal ? '-\$120.00' : '+\$45.00',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isWithdrawal ? textPrimary : successGreen,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Completed',
                    style: TextStyle(
                      color: successGreen.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
