import 'package:flutter/material.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final transactions = [
      {'title': 'Paid to Uber', 'amount': '-Rs. 450.00', 'date': '24 Feb, 2026', 'icon': Icons.local_taxi, 'status': 'Success'},
      {'title': 'Received from Shahid', 'amount': '+Rs. 1,200.00', 'date': '22 Feb, 2026', 'icon': Icons.swap_horiz, 'status': 'Success'},
      {'title': 'Netflix Subscription', 'amount': '-Rs. 950.00', 'date': '20 Feb, 2026', 'icon': Icons.tv, 'status': 'Success'},
      {'title': 'Cash Back Reward', 'amount': '+Rs. 25.00', 'date': '18 Feb, 2026', 'icon': Icons.card_giftcard, 'status': 'Success'},
      {'title': 'Zong Recharge', 'amount': '-Rs. 500.00', 'date': '15 Feb, 2026', 'icon': Icons.phone_android, 'status': 'Failed'},
    ];

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final bool isCredit = (tx['amount'] as String).startsWith('+');
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: (tx['icon'] as IconData) == Icons.phone_android ? Colors.teal : Colors.grey.shade100,
                child: Icon(tx['icon'] as IconData, size: 20, color: (tx['icon'] as IconData) == Icons.phone_android ? Colors.white : Colors.black87),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      tx['date'] as String,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tx['amount'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isCredit ? Colors.green : Colors.black,
                    ),
                  ),
                  Text(
                    tx['status'] as String,
                    style: TextStyle(
                      color: (tx['status'] as String) == 'Failed' ? Colors.red : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
