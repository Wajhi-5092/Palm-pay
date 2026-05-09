import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { sale, withdrawal, deposit }

enum TransactionStatus { pending, completed, failed }

class Transaction {
  final String id;
  final String merchantId;
  final TransactionType type;
  final double amount;
  final double commission;
  final double netAmount;
  final TransactionStatus status;
  final String? orderId;
  final String? customerName;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? referenceId; // For withdrawals

  Transaction({
    required this.id,
    required this.merchantId,
    required this.type,
    required this.amount,
    this.commission = 0.0,
    required this.netAmount,
    this.status = TransactionStatus.pending,
    this.orderId,
    this.customerName,
    this.description,
    required this.createdAt,
    this.completedAt,
    this.referenceId,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      merchantId: data['merchantId'] ?? '',
      type: TransactionType.values[data['type'] ?? 0],
      amount: (data['amount'] ?? 0.0).toDouble(),
      commission: (data['commission'] ?? 0.0).toDouble(),
      netAmount: (data['netAmount'] ?? 0.0).toDouble(),
      status: TransactionStatus.values[data['status'] ?? 0],
      orderId: data['orderId'],
      customerName: data['customerName'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      referenceId: data['referenceId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'merchantId': merchantId,
      'type': type.index,
      'amount': amount,
      'commission': commission,
      'netAmount': netAmount,
      'status': status.index,
      'orderId': orderId,
      'customerName': customerName,
      'description': description,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'referenceId': referenceId,
    };
  }
}
