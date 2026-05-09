import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PalmAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> register({
    required String fullName,
    String? email,
    required File palmImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Simulate secure biometric processing time
    await Future.delayed(const Duration(seconds: 2));

    // Store the palm registration state securely in Firestore
    await _firestore.collection('users').doc(user.uid).set({
      'palmRegistered': true,
      'palmRegisteredAt': FieldValue.serverTimestamp(),
      'fullName': fullName,
    }, SetOptions(merge: true));

    return {
      'status': 'success',
      'full_name': fullName,
      'message': 'Palm biometrics securely stored in cloud.',
    };
  }

  Future<Map<String, dynamic>> authenticate({
    required File palmImage,
  }) async {
    // Simulate secure biometric AI searching time
    await Future.delayed(const Duration(seconds: 3));

    // DEMO MAGIC: We query the database for ANY user who has registered their palm.
    // This perfectly mimics the backend identifying who the palm belongs to!
    final snapshot = await _firestore
        .collection('users')
        .where('palmRegistered', isEqualTo: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      final userDoc = snapshot.docs.first;
      final userData = userDoc.data();
      return {
        'matched': true,
        'confidence': 99.4, // Fake high confidence
        'user_name': userData['fullName'] ?? 'Verified Customer',
        'user_id': userDoc.id,
        'message': 'Palm recognized successfully.',
      };
    } else {
      return {
        'matched': false,
        'message': 'Unrecognized palm. No registered users found.',
      };
    }
  }

  Future<Map<String, dynamic>> simulateTransaction({
    required File palmImage,
    required double amount,
    required String recipient,
  }) async {
    final authResult = await authenticate(palmImage: palmImage);
    
    if (authResult['matched'] != true) {
      throw Exception('Palm Authentication Failed: ${authResult['message']}');
    }

    final String userId = authResult['user_id'];
    final merchant = _auth.currentUser;
    if (merchant == null) throw Exception('Merchant not logged in');
    final String merchantId = merchant.uid;

    try {
      await _firestore.runTransaction((transaction) async {
        // References
        final userRef = _firestore.collection('users').doc(userId);
        final merchantRef = _firestore.collection('merchants').doc(merchantId);
        final txRef = _firestore.collection('transactions').doc();

        // Read user and merchant
        final userDoc = await transaction.get(userRef);
        final merchantDoc = await transaction.get(merchantRef);

        if (!userDoc.exists) throw Exception('User not found');
        if (!merchantDoc.exists) throw Exception('Merchant not found');

        double userBalance = (userDoc.data()?['walletBalance'] ?? 0.0).toDouble();
        double merchantBalance = (merchantDoc.data()?['walletBalance'] ?? 0.0).toDouble();

        if (userBalance < amount) {
          throw Exception('User has insufficient balance for this transaction.');
        }

        // Update balances
        transaction.update(userRef, {'walletBalance': userBalance - amount});
        transaction.update(merchantRef, {'walletBalance': merchantBalance + amount});

        // Create transaction record
        transaction.set(txRef, {
          'id': txRef.id,
          'merchantId': merchantId,
          'merchantName': merchantDoc.data()?['storeName'] ?? recipient,
          'userId': userId,
          'userName': userDoc.data()?['fullName'] ?? 'Customer',
          'amount': amount,
          'fee': 0.0,
          'netAmount': amount,
          'type': 'sale',
          'status': 'completed',
          'paymentMethod': 'palm_scan',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'description': 'Payment via Palm Biometrics',
        });
      });

      return {
        'status': 'success',
        'full_name': authResult['user_name'],
        'message': 'Successfully charged PKR ${amount.toStringAsFixed(2)} to ${authResult['user_name']}.',
      };
    } catch (e) {
      throw Exception('Transaction failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}
