import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paypalm/models/transaction_model.dart';
import 'package:paypalm/palm/data/palm_simple_firestore_service.dart';
import 'package:paypalm/palm/services/palm_cosine.dart';

/// Client-side palm payout: atomic Firestore transaction (no Cloud Functions).
/// Requires matching [firestore.rules] for merchant wallet updates + transaction create.
class PalmFirestorePaymentService {
  PalmFirestorePaymentService._();

  static double _roundMoney(double v) =>
      double.parse(v.toStringAsFixed(2));

  static List<double> _probeList(Float32List f) {
    return List<double>.generate(f.length, (i) {
      final v = f[i];
      if (!v.isFinite) return 0.0;
      return v.toDouble();
    });
  }

  /// Deducts **[amount] from `users/{customerUid}` only** (matched customer) and credits
  /// `merchants/{merchant}` in one transaction. [customerUid] must be the palm-matched user id.
  /// Re-verifies [embedding] against [palmLookup] for that same [customerUid].
  static Future<Map<String, dynamic>> finalizePalmPaymentDirect({
    required String customerUid,
    required double amount,
    required Float32List embedding,
    String? handId,
    double threshold = PalmSimpleFirestoreService.merchantMatchThreshold,
    String? checkoutSessionId,
  }) async {
    final merchantUid = FirebaseAuth.instance.currentUser?.uid;
    if (merchantUid == null || merchantUid.isEmpty) {
      throw StateError('Not signed in');
    }
    if (merchantUid == customerUid) {
      throw Exception('Cannot charge your own account.');
    }
    final chargeAmount = _roundMoney(amount);
    if (!amount.isFinite || chargeAmount <= 0) {
      throw Exception('Invalid payment amount.');
    }

    final probe = _probeList(embedding);
    if (probe.length < 8) {
      throw Exception('Invalid palm data.');
    }

    final db = FirebaseFirestore.instance;
    final checkoutSid = checkoutSessionId?.trim() ?? '';
    DocumentReference<Map<String, dynamic>>? completionRef;
    if (checkoutSid.isNotEmpty) {
      completionRef = db
          .collection('merchants')
          .doc(merchantUid)
          .collection('palmCheckoutSessions')
          .doc(checkoutSid)
          .collection('completedCustomerIds')
          .doc(customerUid);
    }

    return db.runTransaction((tx) async {
      final lookupRef = db.collection('palmLookup').doc(customerUid);
      final lookupSnap = await tx.get(lookupRef);
      if (!lookupSnap.exists) {
        throw Exception('Customer palm is not enrolled.');
      }
      final lookup = lookupSnap.data()!;
      final storedHand = lookup['handId'] as String?;
      if (handId != null &&
          handId.isNotEmpty &&
          storedHand != null &&
          storedHand != handId) {
        throw Exception('Hand ID does not match this customer.');
      }
      final refEmb = lookup['embedding'];
      if (refEmb is! List) {
        throw Exception('Invalid palm template.');
      }
      final ref = refEmb.map((e) => (e as num).toDouble()).toList();
      if (ref.length != probe.length) {
        throw Exception('Palm template length mismatch.');
      }
      final sim = palmCosineSimilarity(ref, probe);
      if (sim < threshold) {
        throw Exception(
          'Palm verification failed. Ask the customer to scan again.',
        );
      }

      final userRef = db.collection('users').doc(customerUid);
      final merchantRef = db.collection('merchants').doc(merchantUid);
      final txRef = db.collection('transactions').doc();

      if (completionRef != null) {
        final compSnap = await tx.get(completionRef);
        if (compSnap.exists) {
          throw Exception(
            PalmSimpleFirestoreService.palmCheckoutDuplicateCustomerMessage,
          );
        }
      }

      final userSnap = await tx.get(userRef);
      final merchantSnap = await tx.get(merchantRef);
      if (!userSnap.exists) {
        throw Exception('Customer account not found.');
      }
      if (!merchantSnap.exists) {
        throw Exception('Merchant account not found.');
      }

      final userData = userSnap.data()!;
      final merchantData = merchantSnap.data()!;
      final displayName = (userData['name'] as String?)?.trim();
      final dn = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : (lookup['displayName'] as String?)?.trim();
      final customerName = (dn != null && dn.isNotEmpty) ? dn : 'Customer';
      final storeName = (merchantData['storeName'] as String?)?.trim();
      final store =
          (storeName != null && storeName.isNotEmpty) ? storeName : 'Merchant';

      // Matched customer wallet only — `userRef` === users/{customerUid}
      var customerWallet = _roundMoney(
        (userData['walletBalance'] as num?)?.toDouble() ?? 0,
      );
      var merchantWallet = _roundMoney(
        (merchantData['walletBalance'] as num?)?.toDouble() ?? 0,
      );
      if (customerWallet < chargeAmount) {
        throw Exception('Customer has insufficient wallet balance.');
      }

      customerWallet = _roundMoney(customerWallet - chargeAmount);
      merchantWallet = _roundMoney(merchantWallet + chargeAmount);

      tx.update(userRef, {'walletBalance': customerWallet});
      tx.update(merchantRef, {'walletBalance': merchantWallet});

      tx.set(txRef, {
        'id': txRef.id,
        'merchantId': merchantUid,
        'merchantName': store,
        'merchantCode':
            merchantData['merchantId']?.toString().trim() ?? '',
        'merchantCategory':
            merchantData['category']?.toString().trim() ?? '',
        'merchantCity': merchantData['city']?.toString().trim() ?? '',
        'merchantPhone': merchantData['phone']?.toString().trim() ?? '',
        'merchantOwnerName':
            merchantData['ownerName']?.toString().trim() ?? '',
        'userId': customerUid,
        'userName': customerName,
        'customerName': customerName,
        'amount': chargeAmount,
        'fee': 0,
        'commission': 0,
        'netAmount': chargeAmount,
        // Match [Transaction.fromFirestore]: enum indexes + palm_sale label for dashboards.
        'type': TransactionType.sale.index,
        'saleKind': 'palm_sale',
        'status': TransactionStatus.completed.index,
        'paymentMethod': 'palm_lookup_client',
        'final': true,
        'irreversible': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'description':
            'Palm pay — $customerName · PKR ${chargeAmount.toStringAsFixed(2)}',
        if (checkoutSid.isNotEmpty) 'checkoutSessionId': checkoutSid,
      });

      if (completionRef != null) {
        tx.set(completionRef, {
          'customerUid': customerUid,
          'checkoutSessionId': checkoutSid,
          'transactionId': txRef.id,
          'amount': chargeAmount,
          'completedAt': FieldValue.serverTimestamp(),
        });
      }

      final conf = (sim * 1000).round() / 10.0;
      return <String, dynamic>{
        'success': true,
        'userId': customerUid,
        'displayName': customerName,
        'confidence': conf,
        'walletBalance': customerWallet,
        'merchantWalletBalance': merchantWallet,
        'transactionId': txRef.id,
        'amount': chargeAmount,
        'message':
            'Charged PKR ${chargeAmount.toStringAsFixed(2)} to $customerName.',
      };
    });
  }
}
