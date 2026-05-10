import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paypalm/models/transaction_model.dart';

/// Personal user payments: `transactions` where `userId` is the signed-in account.
/// Sorted newest first in memory (no composite index).
class UserTransactionFirestoreService {
  UserTransactionFirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<List<Transaction>> watchCurrentUserTransactions() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const []);
    }
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map(Transaction.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }
}
