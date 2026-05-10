import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Live wallet for personal users — **Firestore** `users/{uid}.walletBalance`.
/// Demo “Add Cash” and palm payments both read/write this field.
class UserWalletFirestoreService {
  UserWalletFirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static double parseWallet(Map<String, dynamic>? data) =>
      (data?['walletBalance'] as num?)?.toDouble() ?? 0.0;

  static Future<double> getWalletBalanceOnce() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return 0;
    return parseWallet(snap.data());
  }

  static Stream<double> watchWalletBalance() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value(0);
    }
    return _db.collection('users').doc(uid).snapshots().map((s) {
      if (!s.exists) return 0;
      return parseWallet(s.data());
    });
  }

  static Future<double> incrementWallet(double amount) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    final ref = _db.collection('users').doc(uid);
    await ref.update({'walletBalance': FieldValue.increment(amount)});
    final snap = await ref.get();
    return parseWallet(snap.data());
  }

  static Future<void> setWalletBalance(double value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    final rounded =
        double.parse(value.toStringAsFixed(2));
    await _db.collection('users').doc(uid).update({'walletBalance': rounded});
  }
}
