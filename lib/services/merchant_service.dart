import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paypalm/services/auth_service.dart';
import '../models/merchant_model.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';
import 'auth_session_service.dart';

class MerchantService {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate unique merchant ID
  String _generateMerchantId() {
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final random = (DateTime.now().microsecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    return 'MRC-$timestamp$random';
  }

  // Register merchant
  Future<Merchant> registerMerchant({
    required String storeName,
    required String ownerName,
    required String category,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String password,
    String? logoUrl,
  }) async {
    try {
      final normalizedEmail = await AuthService().validateEmailForNewAccount(email);

      // Create auth user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      String uid = userCredential.user!.uid;
      String merchantId = _generateMerchantId();

      // Create merchant document
      Merchant merchant = Merchant(
        id: uid,
        merchantId: merchantId,
        storeName: storeName,
        ownerName: ownerName,
        category: category,
        phone: phone,
        email: normalizedEmail,
        address: address,
        city: city,
        logoUrl: logoUrl,
        createdAt: DateTime.now(),
        walletBalance: 0.0,
        isActive: true,
      );

      await _firestore
          .collection('merchants')
          .doc(uid)
          .set(merchant.toFirestore());

      // CRITICAL: Persist session after successful registration
      try {
        final user = userCredential.user;
        if (user != null) {
          final authSession = AuthSessionService();
          await authSession.persistSessionFromUser(user, pendingRefresh: false);
          await authSession.touchActivity();
        }
      } catch (e) {
        print('Warning: Failed to persist auth session after registration: $e');
      }

      return merchant;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'This email is already registered. Sign in or use a different email.',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Login merchant
  Future<Merchant?> loginMerchant(String identifier, String password) async {
    try {
      String emailToUse = identifier;

      // Check if identifier is merchant ID
      if (identifier.startsWith('MRC-') || identifier.startsWith('SHOP-')) {
        final querySnapshot = await _firestore
            .collection('merchants')
            .where('merchantId', isEqualTo: identifier)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception('No merchant found with this ID.');
        }

        emailToUse = querySnapshot.docs.first.data()['email'];
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      String uid = userCredential.user!.uid;
      firestore.DocumentSnapshot doc =
          await _firestore.collection('merchants').doc(uid).get();

      if (!doc.exists) {
        throw Exception('Merchant data not found.');
      }

      // CRITICAL: Persist session after successful login
      try {
        final user = userCredential.user;
        if (user != null) {
          // Import and use AuthSessionService to persist encrypted session metadata
          // This ensures the user stays logged in across app restarts
          final authSession = AuthSessionService();
          await authSession.persistSessionFromUser(user, pendingRefresh: false);
          // Touch activity timestamp
          await authSession.touchActivity();
        }
      } catch (e) {
        // Log but don't fail login if session persistence fails
        print('Warning: Failed to persist auth session: $e');
      }

      return Merchant.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  // Get current merchant
  Future<Merchant?> getCurrentMerchant() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      firestore.DocumentSnapshot doc =
          await _firestore.collection('merchants').doc(user.uid).get();
      if (!doc.exists) return null;

      return Merchant.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // Update merchant profile
  Future<void> updateMerchantProfile(
      String merchantId, Map<String, dynamic> updates) async {
    await _firestore.collection('merchants').doc(merchantId).update(updates);
  }

  // Get merchant transactions
  Stream<List<Transaction>> getMerchantTransactions(String merchantId) {
    return _firestore
        .collection('transactions')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Transaction.fromFirestore(doc))
            .toList());
  }

  // Get merchant withdrawals
  Stream<List<Withdrawal>> getMerchantWithdrawals(String merchantId) {
    return _firestore
        .collection('withdrawals')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Withdrawal.fromFirestore(doc)).toList());
  }

  // Request withdrawal
  Future<void> requestWithdrawal({
    required String merchantId,
    required double amount,
    required WithdrawalMethod method,
    required String accountDetails,
    double fee = 0.0,
  }) async {
    // Check balance
    firestore.DocumentSnapshot merchantDoc =
        await _firestore.collection('merchants').doc(merchantId).get();
    Merchant merchant = Merchant.fromFirestore(merchantDoc);

    if (merchant.walletBalance < amount + fee) {
      throw Exception('Insufficient balance');
    }

    // Create withdrawal
    Withdrawal withdrawal = Withdrawal(
      id: '', // Will be set by Firestore
      merchantId: merchantId,
      amount: amount,
      fee: fee,
      netAmount: amount - fee,
      method: method,
      status: WithdrawalStatus.pending,
      accountDetails: accountDetails,
      requestedAt: DateTime.now(),
    );

    await _firestore.collection('withdrawals').add(withdrawal.toFirestore());

    // Update wallet balance (temporarily deduct)
    await _firestore.collection('merchants').doc(merchantId).update({
      'walletBalance': merchant.walletBalance - amount - fee,
    });
  }

  // Get merchant stats
  Future<Map<String, dynamic>> getMerchantStats(String merchantId) async {
    // Get transactions
    firestore.QuerySnapshot transactionsSnapshot = await _firestore
        .collection('transactions')
        .where('merchantId', isEqualTo: merchantId)
        .get();

    List<Transaction> transactions = transactionsSnapshot.docs
        .map((doc) => Transaction.fromFirestore(doc))
        .toList();

    double totalSales = 0;
    double todaySales = 0;
    double weeklySales = 0;
    double monthlySales = 0;
    int totalOrders = 0;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime weekStart = today.subtract(Duration(days: now.weekday - 1));
    DateTime monthStart = DateTime(now.year, now.month, 1);

    for (Transaction t in transactions) {
      if (t.type == TransactionType.sale &&
          t.status == TransactionStatus.completed) {
        totalSales += t.netAmount;
        totalOrders++;

        if (t.createdAt.isAfter(today)) {
          todaySales += t.netAmount;
        }
        if (t.createdAt.isAfter(weekStart)) {
          weeklySales += t.netAmount;
        }
        if (t.createdAt.isAfter(monthStart)) {
          monthlySales += t.netAmount;
        }
      }
    }

    // Get withdrawals
    firestore.QuerySnapshot withdrawalsSnapshot = await _firestore
        .collection('withdrawals')
        .where('merchantId', isEqualTo: merchantId)
        .get();

    List<Withdrawal> withdrawals = withdrawalsSnapshot.docs
        .map((doc) => Withdrawal.fromFirestore(doc))
        .toList();

    double pendingWithdrawals = withdrawals
        .where((w) =>
            w.status == WithdrawalStatus.pending ||
            w.status == WithdrawalStatus.processing)
        .fold(0, (sum, w) => sum + w.amount);

    double completedWithdrawals = withdrawals
        .where((w) => w.status == WithdrawalStatus.completed)
        .fold(0, (sum, w) => sum + w.amount);

    return {
      'totalSales': totalSales,
      'todaySales': todaySales,
      'weeklySales': weeklySales,
      'monthlySales': monthlySales,
      'totalOrders': totalOrders,
      'pendingWithdrawals': pendingWithdrawals,
      'completedWithdrawals': completedWithdrawals,
    };
  }
}
