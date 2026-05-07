import 'package:cloud_firestore/cloud_firestore.dart';

enum WithdrawalMethod { bankTransfer, easypaisa, jazzcash }

enum WithdrawalStatus { pending, processing, completed, rejected }

class Withdrawal {
  final String id;
  final String merchantId;
  final double amount;
  final double fee;
  final double netAmount;
  final WithdrawalMethod method;
  final WithdrawalStatus status;
  final String accountDetails; // JSON string or map
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? referenceId;
  final String? rejectionReason;

  Withdrawal({
    required this.id,
    required this.merchantId,
    required this.amount,
    this.fee = 0.0,
    required this.netAmount,
    required this.method,
    this.status = WithdrawalStatus.pending,
    required this.accountDetails,
    required this.requestedAt,
    this.processedAt,
    this.referenceId,
    this.rejectionReason,
  });

  factory Withdrawal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Withdrawal(
      id: doc.id,
      merchantId: data['merchantId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      fee: (data['fee'] ?? 0.0).toDouble(),
      netAmount: (data['netAmount'] ?? 0.0).toDouble(),
      method: WithdrawalMethod.values[data['method'] ?? 0],
      status: WithdrawalStatus.values[data['status'] ?? 0],
      accountDetails: data['accountDetails'] ?? '',
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
      referenceId: data['referenceId'],
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'merchantId': merchantId,
      'amount': amount,
      'fee': fee,
      'netAmount': netAmount,
      'method': method.index,
      'status': status.index,
      'accountDetails': accountDetails,
      'requestedAt': requestedAt,
      'processedAt': processedAt,
      'referenceId': referenceId,
      'rejectionReason': rejectionReason,
    };
  }
}
