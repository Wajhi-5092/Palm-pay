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
  /// Store / merchant display name (palm sale rows).
  final String? merchantName;

  /// Human merchant ref from `merchants` doc e.g. MRC-xxxx (not Firebase uid).
  final String? merchantCode;

  final String? merchantCategory;
  final String? merchantCity;
  final String? merchantPhone;

  /// Owner / trading contact name snapshot.
  final String? merchantOwnerName;

  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? referenceId; // For withdrawals

  /// e.g. palm_lookup_client, palm_scan (from Firestore).
  final String? paymentMethod;

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
    this.merchantName,
    this.merchantCode,
    this.merchantCategory,
    this.merchantCity,
    this.merchantPhone,
    this.merchantOwnerName,
    this.description,
    required this.createdAt,
    this.completedAt,
    this.referenceId,
    this.paymentMethod,
  });

  static TransactionType _parseType(dynamic raw) {
    if (raw is int &&
        raw >= 0 &&
        raw < TransactionType.values.length) {
      return TransactionType.values[raw];
    }
    switch (raw?.toString().toLowerCase()) {
      case 'sale':
      case 'palm_sale':
        return TransactionType.sale;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'deposit':
        return TransactionType.deposit;
      default:
        return TransactionType.sale;
    }
  }

  static TransactionStatus _parseStatus(dynamic raw) {
    if (raw is int &&
        raw >= 0 &&
        raw < TransactionStatus.values.length) {
      return TransactionStatus.values[raw];
    }
    switch (raw?.toString().toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.completed;
    }
  }

  static DateTime _parseCreatedAt(Map<String, dynamic> data) {
    final v = data['createdAt'];
    if (v is Timestamp) return v.toDate();
    return DateTime.now();
  }

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final customerName = data['customerName'] as String? ??
        data['userName'] as String?;
    return Transaction(
      id: doc.id,
      merchantId: data['merchantId']?.toString() ?? '',
      type: _parseType(data['type']),
      amount: (data['amount'] ?? 0.0).toDouble(),
      commission:
          (data['commission'] ?? data['fee'] ?? 0.0).toDouble(),
      netAmount: (data['netAmount'] ?? data['amount'] ?? 0.0).toDouble(),
      status: _parseStatus(data['status']),
      orderId: data['orderId'] as String?,
      customerName: customerName,
      merchantName: data['merchantName'] as String?,
      merchantCode: data['merchantCode'] as String?,
      merchantCategory: data['merchantCategory'] as String?,
      merchantCity: data['merchantCity'] as String?,
      merchantPhone: data['merchantPhone'] as String?,
      merchantOwnerName: data['merchantOwnerName'] as String?,
      description: data['description'] as String?,
      createdAt: _parseCreatedAt(data),
      completedAt: data['completedAt'] != null &&
              data['completedAt'] is Timestamp
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      referenceId: data['referenceId'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
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
      if (merchantName != null) 'merchantName': merchantName,
      if (merchantCode != null) 'merchantCode': merchantCode,
      if (merchantCategory != null) 'merchantCategory': merchantCategory,
      if (merchantCity != null) 'merchantCity': merchantCity,
      if (merchantPhone != null) 'merchantPhone': merchantPhone,
      if (merchantOwnerName != null) 'merchantOwnerName': merchantOwnerName,
      'description': description,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'referenceId': referenceId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    };
  }
}
